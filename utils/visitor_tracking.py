"""
Visitor tracking utility functions for the Poem Vision AI application.
This module handles the tracking and analysis of site visitors.
"""

from datetime import datetime, timedelta
import uuid
from flask import request, session
from sqlalchemy import func, desc
from models import db, SiteVisitor, VisitorLog, VisitorStats, User


def track_visitor(user_id=None):
    """
    Track a visitor to the site.

    Args:
        user_id (int): The ID of the logged-in user, if any

    Returns:
        tuple: A tuple containing (visitor_id, is_new_visitor)
    """
    ip_address = request.remote_addr
    user_agent = request.user_agent.string
    referrer = request.referrer

    # Validate the user_id to avoid FK violations
    if user_id is not None:
        user = db.session.get(User, user_id)
        if not user:
            user_id = None  # Reset to avoid FK violation

    # Create or get a visitor session ID
    if 'visitor_session_id' not in session:
        session['visitor_session_id'] = str(uuid.uuid4())
    session_id = session['visitor_session_id']

    # Check if this is a returning visitor
    visitor = SiteVisitor.query.filter_by(
        ip_address=ip_address,
        user_agent=user_agent
    ).first()

    is_new_visitor = False

    try:
        if visitor:
            # Update existing visitor
            visitor.last_visit = datetime.utcnow()
            visitor.visit_count += 1
            if user_id and not visitor.user_id:
                visitor.user_id = user_id
        else:
            # Create new visitor
            is_new_visitor = True
            visitor = SiteVisitor(
                ip_address=ip_address,
                user_agent=user_agent,
                first_visit=datetime.utcnow(),
                last_visit=datetime.utcnow(),
                visit_count=1,
                user_id=user_id,
                referrer=referrer
            )
            db.session.add(visitor)

        db.session.commit()

        # Create a visitor log entry
        visitor_log = VisitorLog(
            visitor_id=visitor.id,
            page_visited=request.path,
            session_id=session_id
        )
        db.session.add(visitor_log)
        db.session.commit()

    except Exception as e:
        db.session.rollback()
        # Optional: log the error
        print(f"[Visitor Tracking Error] {e}")
        raise

    return visitor.id, is_new_visitor



def update_visitor_stats():
    """
    Update the visitor statistics for the current day, month, and year.
    This should be called periodically (e.g., via a scheduled task).
    """
    today = datetime.utcnow().date()
    
    # Get today's stats record or create a new one
    daily_stats = VisitorStats.query.filter_by(
        date=today,
        period='day'
    ).first()
    
    if not daily_stats:
        daily_stats = VisitorStats(
            date=today,
            period='day'
        )
        db.session.add(daily_stats)
    
    # Get this month's stats record or create a new one
    month_start = datetime(today.year, today.month, 1).date()
    monthly_stats = VisitorStats.query.filter_by(
        date=month_start,
        period='month'
    ).first()
    
    if not monthly_stats:
        monthly_stats = VisitorStats(
            date=month_start,
            period='month'
        )
        db.session.add(monthly_stats)
    
    # Get this year's stats record or create a new one
    year_start = datetime(today.year, 1, 1).date()
    yearly_stats = VisitorStats.query.filter_by(
        date=year_start,
        period='year'
    ).first()
    
    if not yearly_stats:
        yearly_stats = VisitorStats(
            date=year_start,
            period='year'
        )
        db.session.add(yearly_stats)
    
    # Calculate stats for today
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())
    
    # Count unique visitors today
    daily_unique = db.session.query(func.count(func.distinct(VisitorLog.visitor_id))).filter(
        VisitorLog.timestamp.between(today_start, today_end)
    ).scalar() or 0
    
    # Count total visits today
    daily_visits = VisitorLog.query.filter(
        VisitorLog.timestamp.between(today_start, today_end)
    ).count()
    
    # Count new visitors today
    daily_new = SiteVisitor.query.filter(
        SiteVisitor.first_visit.between(today_start, today_end)
    ).count()
    
    # Update daily stats
    daily_stats.unique_visitors = daily_unique
    daily_stats.total_visits = daily_visits
    daily_stats.new_visitors = daily_new
    daily_stats.returning_visitors = daily_unique - daily_new if daily_unique > daily_new else 0
    
    # Calculate average duration for today
    durations = db.session.query(VisitorLog.time_spent_seconds).filter(
        VisitorLog.timestamp.between(today_start, today_end),
        VisitorLog.time_spent_seconds.isnot(None)
    ).all()
    
    if durations:
        avg_duration = sum(d[0] for d in durations) / len(durations)
        daily_stats.average_duration = avg_duration
    
    # Calculate stats for this month
    month_start_dt = datetime.combine(month_start, datetime.min.time())
    month_end = today_end
    
    # Count unique visitors this month
    monthly_unique = db.session.query(func.count(func.distinct(VisitorLog.visitor_id))).filter(
        VisitorLog.timestamp.between(month_start_dt, month_end)
    ).scalar() or 0
    
    # Count total visits this month
    monthly_visits = VisitorLog.query.filter(
        VisitorLog.timestamp.between(month_start_dt, month_end)
    ).count()
    
    # Count new visitors this month
    monthly_new = SiteVisitor.query.filter(
        SiteVisitor.first_visit.between(month_start_dt, month_end)
    ).count()
    
    # Update monthly stats
    monthly_stats.unique_visitors = monthly_unique
    monthly_stats.total_visits = monthly_visits
    monthly_stats.new_visitors = monthly_new
    monthly_stats.returning_visitors = monthly_unique - monthly_new if monthly_unique > monthly_new else 0
    
    # Calculate average duration for this month
    month_durations = db.session.query(VisitorLog.time_spent_seconds).filter(
        VisitorLog.timestamp.between(month_start_dt, month_end),
        VisitorLog.time_spent_seconds.isnot(None)
    ).all()
    
    if month_durations:
        month_avg_duration = sum(d[0] for d in month_durations) / len(month_durations)
        monthly_stats.average_duration = month_avg_duration
    
    # Calculate stats for this year
    year_start_dt = datetime.combine(year_start, datetime.min.time())
    year_end = today_end
    
    # Count unique visitors this year
    yearly_unique = db.session.query(func.count(func.distinct(VisitorLog.visitor_id))).filter(
        VisitorLog.timestamp.between(year_start_dt, year_end)
    ).scalar() or 0
    
    # Count total visits this year
    yearly_visits = VisitorLog.query.filter(
        VisitorLog.timestamp.between(year_start_dt, year_end)
    ).count()
    
    # Count new visitors this year
    yearly_new = SiteVisitor.query.filter(
        SiteVisitor.first_visit.between(year_start_dt, year_end)
    ).count()
    
    # Update yearly stats
    yearly_stats.unique_visitors = yearly_unique
    yearly_stats.total_visits = yearly_visits
    yearly_stats.new_visitors = yearly_new
    yearly_stats.returning_visitors = yearly_unique - yearly_new if yearly_unique > yearly_new else 0
    
    # Calculate average duration for this year
    year_durations = db.session.query(VisitorLog.time_spent_seconds).filter(
        VisitorLog.timestamp.between(year_start_dt, year_end),
        VisitorLog.time_spent_seconds.isnot(None)
    ).all()
    
    if year_durations:
        year_avg_duration = sum(d[0] for d in year_durations) / len(year_durations)
        yearly_stats.average_duration = year_avg_duration
    
    # Commit all changes
    db.session.commit()
    
    return {
        'daily': daily_stats,
        'monthly': monthly_stats,
        'yearly': yearly_stats
    }


def get_page_popularity(limit=10):
    """
    Get the most popular pages on the site.
    
    Args:
        limit (int): The number of pages to return
        
    Returns:
        list: A list of tuples containing (page_url, visit_count)
    """
    popular_pages = db.session.query(
        VisitorLog.page_visited,
        func.count(VisitorLog.id).label('visits')
    ).group_by(
        VisitorLog.page_visited
    ).order_by(
        desc('visits')
    ).limit(limit).all()
    
    return popular_pages


def get_referrer_stats(limit=10):
    """
    Get the most common referrers to the site.
    
    Args:
        limit (int): The number of referrers to return
        
    Returns:
        list: A list of tuples containing (referrer_url, visitor_count)
    """
    referrer_stats = db.session.query(
        SiteVisitor.referrer,
        func.count(SiteVisitor.id).label('visitors')
    ).filter(
        SiteVisitor.referrer.isnot(None)
    ).group_by(
        SiteVisitor.referrer
    ).order_by(
        desc('visitors')
    ).limit(limit).all()
    
    return referrer_stats


def populate_demo_data():
    """
    Populate demo data for visitor statistics.
    This is for development purposes only.
    """
    today = datetime.utcnow().date()
    
    # Generate daily stats for the past 30 days
    for i in range(30):
        day = today - timedelta(days=i)
        day_stats = VisitorStats.query.filter_by(
            date=day,
            period='day'
        ).first()
        
        if not day_stats:
            # Generate random but realistic stats
            day_stats = VisitorStats(
                date=day,
                period='day',
                unique_visitors=50 + (30 - i) * 2,  # More recent days have higher numbers
                total_visits=70 + (30 - i) * 3,
                new_visitors=20 + (30 - i),
                returning_visitors=30 + (30 - i)
            )
            db.session.add(day_stats)
    
    # Generate monthly stats for the past 12 months
    for i in range(12):
        month = today.replace(day=1) - timedelta(days=i * 30)
        month_stats = VisitorStats.query.filter_by(
            date=month,
            period='month'
        ).first()
        
        if not month_stats:
            # Generate random but realistic stats
            month_stats = VisitorStats(
                date=month,
                period='month',
                unique_visitors=1500 + (12 - i) * 100,
                total_visits=2100 + (12 - i) * 150,
                new_visitors=600 + (12 - i) * 40,
                returning_visitors=900 + (12 - i) * 60
            )
            db.session.add(month_stats)
    
    # Generate yearly stats for the past 5 years
    for i in range(5):
        year = today.replace(month=1, day=1) - timedelta(days=i * 365)
        year_stats = VisitorStats.query.filter_by(
            date=year,
            period='year'
        ).first()
        
        if not year_stats:
            # Generate random but realistic stats
            year_stats = VisitorStats(
                date=year,
                period='year',
                unique_visitors=18000 + (5 - i) * 4000,
                total_visits=25000 + (5 - i) * 6000,
                new_visitors=7000 + (5 - i) * 1500,
                returning_visitors=11000 + (5 - i) * 2500
            )
            db.session.add(year_stats)
    
    db.session.commit()