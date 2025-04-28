import os
import logging
import functools
from datetime import datetime, timedelta
from flask import render_template, request, redirect, url_for, session, flash, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import desc, func
from models import db, User, Creation, Membership, Transaction, AdminUser, AdminRole, AdminLog
from admin import admin_bp

# Set up logging
logger = logging.getLogger(__name__)

# Add context processor to provide current date/time to all templates
@admin_bp.context_processor
def inject_now():
    return {'now': datetime.now()}

# Admin authentication decorator
def admin_required(f):
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        # Check if admin is logged in
        if 'admin_id' not in session:
            flash('You need to be logged in to access the admin area.', 'danger')
            return redirect(url_for('admin.login', next=request.url))
        
        # Get the admin user
        admin = AdminUser.query.get(session['admin_id'])
        if not admin or not admin.is_active:
            session.pop('admin_id', None)
            flash('Admin account is not active or does not exist.', 'danger')
            return redirect(url_for('admin.login'))
        
        # Set admin user for use in templates
        current_app.jinja_env.globals['current_admin'] = admin
        
        return f(*args, **kwargs)
    return decorated_function

# Permission checker decorator
def permission_required(permission):
    def decorator(f):
        @functools.wraps(f)
        def decorated_function(*args, **kwargs):
            # First check if admin is logged in
            if 'admin_id' not in session:
                flash('You need to be logged in to access the admin area.', 'danger')
                return redirect(url_for('admin.login', next=request.url))
            
            # Get the admin user
            admin = AdminUser.query.get(session['admin_id'])
            if not admin or not admin.is_active:
                session.pop('admin_id', None)
                flash('Admin account is not active or does not exist.', 'danger')
                return redirect(url_for('admin.login'))
            
            # Check permission
            if not admin.has_permission(permission):
                flash(f'You do not have the {permission} permission to access this area.', 'danger')
                return redirect(url_for('admin.dashboard'))
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# Helper function to log admin actions
def log_admin_action(action, entity_type=None, entity_id=None, details=None):
    if 'admin_id' not in session:
        return
    
    log = AdminLog(
        admin_id=session['admin_id'],
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        details=details,
        ip_address=request.remote_addr
    )
    db.session.add(log)
    db.session.commit()

# Routes
@admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    # Clear any existing session
    if 'admin_id' in session:
        session.pop('admin_id', None)
    
    # Handle login form submission
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        admin = AdminUser.query.filter_by(username=username).first()
        
        if admin and admin.check_password(password) and admin.is_active:
            # Set session
            session['admin_id'] = admin.id
            
            # Update last login
            admin.last_login = datetime.utcnow()
            db.session.commit()
            
            # Log the login
            log_admin_action('login')
            
            # Redirect to dashboard
            flash('Login successful!', 'success')
            next_page = request.args.get('next')
            if next_page:
                return redirect(next_page)
            return redirect(url_for('admin.dashboard'))
        else:
            flash('Invalid username or password.', 'danger')
    
    return render_template('admin/login.html')

@admin_bp.route('/logout')
def logout():
    if 'admin_id' in session:
        # Log the logout
        log_admin_action('logout')
        # Clear session
        session.pop('admin_id', None)
        flash('You have been logged out.', 'info')
    
    return redirect(url_for('admin.login'))

@admin_bp.route('/')
@admin_required
def dashboard():
    # Basic metrics for dashboard
    total_users = User.query.count()
    active_premium = User.query.filter_by(is_premium=True).count()
    total_creations = Creation.query.count()
    verified_users = User.query.filter_by(is_email_verified=True).count()
    
    # Date ranges
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    one_day_ago = datetime.utcnow() - timedelta(days=1)
    
    # Verification percentage
    verified_percent = (verified_users / total_users * 100) if total_users > 0 else 0
    
    # Premium conversion rate
    premium_percent = (active_premium / total_users * 100) if total_users > 0 else 0
    
    # Revenue data (last 30 days)
    recent_transactions = Transaction.query.filter(
        Transaction.created_at >= thirty_days_ago,
        Transaction.status == 'completed'
    ).all()
    
    recent_revenue = sum(t.amount for t in recent_transactions)
    
    # Download statistics
    total_downloads = db.session.query(func.sum(Creation.download_count)).scalar() or 0
    downloaded_creations = Creation.query.filter(Creation.is_downloaded == True).count()
    download_rate = (downloaded_creations / total_creations * 100) if total_creations > 0 else 0
    
    # Session statistics
    from models import UserSession
    
    active_sessions = UserSession.query.filter(
        UserSession.session_start >= one_day_ago,
        UserSession.session_end.is_(None)
    ).count()
    
    # Avg session duration (for completed sessions)
    avg_session_duration = db.session.query(
        func.avg(UserSession.duration_seconds)
    ).filter(
        UserSession.duration_seconds.isnot(None)
    ).scalar() or 0
    
    avg_session_minutes = avg_session_duration / 60
    
    # Total session time (hours)
    total_session_seconds = db.session.query(
        func.sum(UserSession.duration_seconds)
    ).filter(
        UserSession.duration_seconds.isnot(None)
    ).scalar() or 0
    
    total_session_hours = total_session_seconds / 3600
    
    # Time saved estimate (hours)
    total_time_saved = db.session.query(
        func.sum(Creation.time_saved_minutes)
    ).scalar() or 0
    
    total_time_saved_hours = total_time_saved / 60
    
    # Chart data - user activity over 30 days
    activity_dates = []
    active_users_data = []
    poems_created_data = []
    
    current_date = thirty_days_ago.date()
    end_date = datetime.utcnow().date()
    
    while current_date <= end_date:
        # Format date for display
        activity_dates.append(current_date.strftime('%b %d'))
        
        # Count users active on this day
        day_start = datetime.combine(current_date, datetime.min.time())
        day_end = datetime.combine(current_date, datetime.max.time())
        
        active_users = UserSession.query.filter(
            UserSession.session_start.between(day_start, day_end)
        ).with_entities(UserSession.user_id).distinct().count()
        
        # Count poems created on this day
        day_poems = Creation.query.filter(
            Creation.created_at.between(day_start, day_end)
        ).count()
        
        active_users_data.append(active_users)
        poems_created_data.append(day_poems)
        
        current_date += timedelta(days=1)
    
    # Poem types distribution
    poem_types_data = db.session.query(
        Creation.poem_type,
        func.count(Creation.id)
    ).filter(
        Creation.poem_type.isnot(None)
    ).group_by(
        Creation.poem_type
    ).all()
    
    poem_types_labels = [pt[0] for pt in poem_types_data]
    poem_types_counts = [pt[1] for pt in poem_types_data]
    
    # Recent activity for admin logs
    recent_activity = AdminLog.query.order_by(AdminLog.timestamp.desc()).limit(10).all()
    
    return render_template(
        'admin/dashboard.html',
        # Basic metrics
        total_users=total_users,
        active_premium=active_premium,
        total_creations=total_creations,
        verified_users=verified_users,
        verified_percent=verified_percent,
        premium_percent=premium_percent,
        recent_revenue=recent_revenue,
        recent_activity=recent_activity,
        
        # Enhanced metrics
        total_downloads=total_downloads,
        download_rate=download_rate,
        active_sessions=active_sessions,
        avg_session_minutes=avg_session_minutes,
        total_session_hours=total_session_hours,
        total_time_saved_hours=total_time_saved_hours,
        
        # Chart data
        activity_dates=activity_dates,
        active_users_data=active_users_data, 
        poems_created_data=poems_created_data,
        poem_types_labels=poem_types_labels,
        poem_types_counts=poem_types_counts
    )

# User Management
@admin_bp.route('/users')
@admin_required
@permission_required('view_users')
def users():
    # Get filter parameters
    is_premium = request.args.get('is_premium')
    search = request.args.get('search')
    sort_by = request.args.get('sort_by', 'created_at')
    sort_dir = request.args.get('sort_dir', 'desc')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    # Start with base query
    query = User.query
    
    # Apply filters
    if is_premium:
        is_premium_bool = is_premium.lower() == 'true'
        query = query.filter(User.is_premium == is_premium_bool)
    
    if search:
        query = query.filter(
            (User.username.ilike(f'%{search}%')) | 
            (User.email.ilike(f'%{search}%'))
        )
    
    # Apply sorting
    if sort_by == 'username':
        sort_col = User.username
    elif sort_by == 'email':
        sort_col = User.email
    elif sort_by == 'is_premium':
        sort_col = User.is_premium
    else:  # Default to created_at
        sort_col = User.created_at
    
    if sort_dir == 'asc':
        query = query.order_by(sort_col.asc())
    else:
        query = query.order_by(sort_col.desc())
    
    # Paginate results
    users = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return render_template(
        'admin/users.html',
        users=users,
        is_premium=is_premium,
        search=search,
        sort_by=sort_by,
        sort_dir=sort_dir
    )

@admin_bp.route('/users/<int:user_id>')
@admin_required
@permission_required('view_users')
def user_detail(user_id):
    user = User.query.get_or_404(user_id)
    
    # Get user creations
    creations = Creation.query.filter_by(user_id=user_id).order_by(Creation.created_at.desc()).all()
    
    # Get user transactions
    transactions = Transaction.query.filter_by(user_id=user_id).order_by(Transaction.created_at.desc()).all()
    
    # Get time saved stats
    time_saved = user.get_time_saved_stats()
    
    # Get poem preferences and download stats
    poem_preferences = user.get_poem_preferences()
    
    # Get session statistics
    session_stats = user.get_session_stats()
    
    return render_template(
        'admin/user_detail.html',
        user=user,
        creations=creations,
        transactions=transactions,
        time_saved=time_saved,
        poem_preferences=poem_preferences,
        session_stats=session_stats
    )

@admin_bp.route('/users/<int:user_id>/toggle-premium', methods=['POST'])
@admin_required
@permission_required('edit_users')
def toggle_premium(user_id):
    user = User.query.get_or_404(user_id)
    
    # Toggle premium status
    user.is_premium = not user.is_premium
    
    # If setting to premium, set membership period
    if user.is_premium:
        user.membership_start = datetime.utcnow()
        user.membership_end = datetime.utcnow() + timedelta(days=30)  # Default to 30 days
        user.is_cancelled = False
    else:
        user.membership_end = datetime.utcnow()
        user.is_cancelled = True
    
    db.session.commit()
    
    # Log the action
    log_admin_action(
        'toggle_premium', 
        'user', 
        user.id, 
        {'new_status': user.is_premium}
    )
    
    flash(f"Premium status for {user.username} has been {'activated' if user.is_premium else 'deactivated'}.", 'success')
    return redirect(url_for('admin.user_detail', user_id=user.id))

@admin_bp.route('/users/<int:user_id>/verify-email', methods=['POST'])
@admin_required
@permission_required('edit_users')
def verify_user_email(user_id):
    user = User.query.get_or_404(user_id)
    
    if user.is_email_verified:
        flash(f"User {user.username}'s email is already verified.", 'info')
    else:
        user.verify_email()
        db.session.commit()
        
        # Log the action
        log_admin_action('verify_email', 'user', user.id, {
            'email': user.email,
            'username': user.username
        })
        
        flash(f"User {user.username}'s email has been manually verified.", 'success')
    
    return redirect(url_for('admin.user_detail', user_id=user.id))

@admin_bp.route('/users/<int:user_id>/delete', methods=['POST'])
@admin_required
@permission_required('delete_users')
def delete_user(user_id):
    user = User.query.get_or_404(user_id)
    username = user.username
    
    # Record for logging
    user_data = {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'is_premium': user.is_premium,
        'created_at': user.created_at.isoformat() if user.created_at else None
    }
    
    # Delete user (this will cascade to related entities)
    db.session.delete(user)
    db.session.commit()
    
    # Log the action
    log_admin_action('delete_user', 'user', user_id, user_data)
    
    flash(f"User {username} has been deleted.", 'success')
    return redirect(url_for('admin.users'))

# Membership Management
@admin_bp.route('/memberships')
@admin_required
@permission_required('view_memberships')
def memberships():
    memberships = Membership.query.all()
    
    # Get additional data for the template
    total_users = User.query.count()
    active_premium = User.query.filter_by(is_premium=True).count()
    premium_percent = (active_premium / total_users * 100) if total_users > 0 else 0
    
    # Average revenue per user
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    revenue = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.created_at >= thirty_days_ago,
        Transaction.status == 'completed'
    ).scalar() or 0
    
    arpu = revenue / total_users if total_users > 0 else 0
    
    return render_template(
        'admin/memberships.html', 
        memberships=memberships,
        total_users=total_users,
        active_premium=active_premium,
        premium_percent=premium_percent,
        arpu=arpu
    )

@admin_bp.route('/memberships/<int:membership_id>/edit', methods=['GET', 'POST'])
@admin_required
@permission_required('edit_memberships')
def edit_membership(membership_id):
    membership = Membership.query.get_or_404(membership_id)
    
    # Count users on this membership plan
    if membership.price > 0:
        # This is a premium plan
        membership_usage = User.query.filter_by(is_premium=True).count()
    else:
        # This is a free plan
        membership_usage = User.query.filter_by(is_premium=False).count()
    
    if request.method == 'POST':
        membership.name = request.form.get('name')
        membership.price = float(request.form.get('price'))
        membership.description = request.form.get('description')
        membership.max_poem_types = int(request.form.get('max_poem_types'))
        membership.max_frame_types = int(request.form.get('max_frame_types'))
        membership.max_saved_poems = int(request.form.get('max_saved_poems'))
        membership.has_gallery = 'has_gallery' in request.form
        
        # Optional fields
        stripe_price_id = request.form.get('stripe_price_id')
        if stripe_price_id:
            membership.stripe_price_id = stripe_price_id
        
        db.session.commit()
        
        # Log the action
        log_admin_action('edit_membership', 'membership', membership.id)
        
        flash(f"Membership {membership.name} has been updated.", 'success')
        return redirect(url_for('admin.memberships'))
    
    return render_template('admin/edit_membership.html', 
                          membership=membership,
                          membership_usage=membership_usage)

# Financial Reports
@admin_bp.route('/financial')
@admin_required
@permission_required('view_financial')
def financial():
    # Get date range from query params or default to last 30 days
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')
    
    try:
        if start_date_str:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
        else:
            start_date = datetime.utcnow() - timedelta(days=30)
            
        if end_date_str:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
            # Set to end of day
            end_date = end_date.replace(hour=23, minute=59, second=59)
        else:
            end_date = datetime.utcnow()
    except ValueError:
        flash("Invalid date format. Using default range (last 30 days).", 'warning')
        start_date = datetime.utcnow() - timedelta(days=30)
        end_date = datetime.utcnow()
    
    # Get completed transactions in date range
    transactions = Transaction.query.filter(
        Transaction.created_at.between(start_date, end_date),
        Transaction.status == 'completed'
    ).order_by(Transaction.created_at.desc()).all()
    
    # Calculate summary metrics
    total_revenue = sum(t.amount for t in transactions)
    transaction_count = len(transactions)
    avg_transaction = total_revenue / transaction_count if transaction_count > 0 else 0
    
    # Group by day for chart
    daily_revenue = {}
    current_date = start_date
    while current_date <= end_date:
        day_str = current_date.strftime('%Y-%m-%d')
        daily_revenue[day_str] = 0
        current_date += timedelta(days=1)
    
    for t in transactions:
        day_str = t.created_at.strftime('%Y-%m-%d')
        if day_str in daily_revenue:
            daily_revenue[day_str] += t.amount
    
    # Convert to sorted list for chart
    revenue_data = [
        {'date': k, 'amount': float(v)}  # Ensure amount is a float for JSON serialization
        for k, v in sorted(daily_revenue.items())
    ]
    
    # We don't need to set the tojson filter as it's built into Flask
    
    return render_template(
        'admin/financial.html',
        transactions=transactions,
        total_revenue=total_revenue,
        transaction_count=transaction_count,
        avg_transaction=avg_transaction,
        revenue_data=revenue_data,
        start_date=start_date.strftime('%Y-%m-%d'),
        end_date=end_date.strftime('%Y-%m-%d')
    )

# Analytics
@admin_bp.route('/analytics')
@admin_required
@permission_required('view_analytics')
def analytics():
    # Get poem type distribution
    poem_types = db.session.query(
        Creation.poem_type, 
        func.count(Creation.id)
    ).filter(
        Creation.poem_type.isnot(None)
    ).group_by(
        Creation.poem_type
    ).all()
    
    # Get frame style distribution
    frame_styles = db.session.query(
        Creation.frame_style, 
        func.count(Creation.id)
    ).filter(
        Creation.frame_style.isnot(None)
    ).group_by(
        Creation.frame_style
    ).all()
    
    # Get poem length distribution
    poem_lengths = db.session.query(
        Creation.poem_length, 
        func.count(Creation.id)
    ).filter(
        Creation.poem_length.isnot(None)
    ).group_by(
        Creation.poem_length
    ).all()
    
    # Calculate total time saved
    total_time_saved = db.session.query(
        func.sum(Creation.time_saved_minutes)
    ).filter(
        Creation.time_saved_minutes.isnot(None)
    ).scalar() or 0
    
    # Format for display
    hours_saved = total_time_saved // 60
    minutes_saved = total_time_saved % 60
    
    # Daily poem generation over last 30 days
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    daily_creations = db.session.query(
        func.date(Creation.created_at),
        func.count(Creation.id)
    ).filter(
        Creation.created_at >= thirty_days_ago
    ).group_by(
        func.date(Creation.created_at)
    ).all()
    
    # Convert to dict for easy chart rendering
    daily_data = {}
    current_date = thirty_days_ago.date()
    end_date = datetime.utcnow().date()
    
    while current_date <= end_date:
        daily_data[current_date.isoformat()] = 0
        current_date += timedelta(days=1)
    
    for date, count in daily_creations:
        daily_data[date.isoformat()] = count
    
    # Convert to sorted list for chart
    creation_data = [
        {'date': k, 'count': v} 
        for k, v in sorted(daily_data.items())
    ]
    
    return render_template(
        'admin/analytics.html',
        poem_types=poem_types,
        frame_styles=frame_styles,
        poem_lengths=poem_lengths,
        total_time_saved=total_time_saved,
        hours_saved=hours_saved,
        minutes_saved=minutes_saved,
        creation_data=creation_data
    )

# Admin User Management
@admin_bp.route('/admins')
@admin_required
@permission_required('view_admins')
def admins():
    admin_users = AdminUser.query.all()
    admin_roles = AdminRole.query.all()
    return render_template('admin/admins.html', admin_users=admin_users, admin_roles=admin_roles)

@admin_bp.route('/admins/create', methods=['GET', 'POST'])
@admin_required
@permission_required('edit_admins')
def create_admin():
    roles = AdminRole.query.all()
    
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        role_id = request.form.get('role_id')
        
        # Check if username or email already exists
        if AdminUser.query.filter_by(username=username).first():
            flash('Username already exists.', 'danger')
            return render_template('admin/create_admin.html', roles=roles)
        
        if AdminUser.query.filter_by(email=email).first():
            flash('Email already exists.', 'danger')
            return render_template('admin/create_admin.html', roles=roles)
        
        # Create new admin user
        admin = AdminUser(
            username=username,
            email=email,
            role_id=role_id
        )
        admin.set_password(password)
        
        db.session.add(admin)
        db.session.commit()
        
        # Log the action
        log_admin_action('create_admin', 'admin_user', admin.id)
        
        flash(f"Admin user {username} has been created.", 'success')
        return redirect(url_for('admin.admins'))
    
    return render_template('admin/create_admin.html', roles=roles)

@admin_bp.route('/admins/<int:admin_id>/edit', methods=['GET', 'POST'])
@admin_required
@permission_required('edit_admins')
def edit_admin(admin_id):
    admin = AdminUser.query.get_or_404(admin_id)
    roles = AdminRole.query.all()
    
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        role_id = request.form.get('role_id')
        is_active = 'is_active' in request.form
        
        # Check if username already exists (for another admin)
        existing_admin = AdminUser.query.filter_by(username=username).first()
        if existing_admin and existing_admin.id != admin_id:
            flash('Username already exists.', 'danger')
            return render_template('admin/edit_admin.html', admin=admin, roles=roles)
        
        # Check if email already exists (for another admin)
        existing_admin = AdminUser.query.filter_by(email=email).first()
        if existing_admin and existing_admin.id != admin_id:
            flash('Email already exists.', 'danger')
            return render_template('admin/edit_admin.html', admin=admin, roles=roles)
        
        # Update admin user
        admin.username = username
        admin.email = email
        admin.role_id = role_id
        admin.is_active = is_active
        
        if password:
            admin.set_password(password)
        
        db.session.commit()
        
        # Log the action
        log_admin_action('edit_admin', 'admin_user', admin.id)
        
        flash(f"Admin user {username} has been updated.", 'success')
        return redirect(url_for('admin.admins'))
    
    return render_template('admin/edit_admin.html', admin=admin, roles=roles)

@admin_bp.route('/roles')
@admin_required
@permission_required('view_roles')
def roles():
    roles = AdminRole.query.all()
    return render_template('admin/roles.html', roles=roles)

@admin_bp.route('/roles/create', methods=['GET', 'POST'])
@admin_required
@permission_required('edit_roles')
def create_role():
    # Define all available permissions
    all_permissions = [
        'view_users', 'edit_users', 'delete_users',
        'view_memberships', 'edit_memberships',
        'view_financial', 'process_refunds',
        'view_analytics',
        'view_admins', 'edit_admins',
        'view_roles', 'edit_roles',
        'view_logs'
    ]
    
    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')
        
        # Get selected permissions
        permissions = []
        for perm in all_permissions:
            if perm in request.form:
                permissions.append(perm)
        
        # Create new role
        role = AdminRole(
            name=name,
            description=description,
            permissions={'allowed': permissions}
        )
        
        db.session.add(role)
        db.session.commit()
        
        # Log the action
        log_admin_action('create_role', 'admin_role', role.id)
        
        flash(f"Role {name} has been created.", 'success')
        return redirect(url_for('admin.roles'))
    
    return render_template('admin/create_role.html', permissions=all_permissions)

@admin_bp.route('/roles/<int:role_id>/edit', methods=['GET', 'POST'])
@admin_required
@permission_required('edit_roles')
def edit_role(role_id):
    role = AdminRole.query.get_or_404(role_id)
    
    # Define all available permissions
    all_permissions = [
        'view_users', 'edit_users', 'delete_users',
        'view_memberships', 'edit_memberships',
        'view_financial', 'process_refunds',
        'view_analytics',
        'view_admins', 'edit_admins',
        'view_roles', 'edit_roles',
        'view_logs'
    ]
    
    # Get currently assigned permissions
    current_permissions = role.permissions.get('allowed', []) if role.permissions else []
    
    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')
        
        # Get selected permissions
        permissions = []
        for perm in all_permissions:
            if perm in request.form:
                permissions.append(perm)
        
        # Update role
        role.name = name
        role.description = description
        role.permissions = {'allowed': permissions}
        
        db.session.commit()
        
        # Log the action
        log_admin_action('edit_role', 'admin_role', role.id)
        
        flash(f"Role {name} has been updated.", 'success')
        return redirect(url_for('admin.roles'))
    
    return render_template(
        'admin/edit_role.html', 
        role=role, 
        permissions=all_permissions,
        current_permissions=current_permissions
    )

# Activity Logs
@admin_bp.route('/logs')
@admin_required
@permission_required('view_logs')
def logs():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)
    
    logs = AdminLog.query.order_by(AdminLog.timestamp.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return render_template('admin/logs.html', logs=logs)