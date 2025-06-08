import 'package:equatable/equatable.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';

/// User profile model
class UserProfile extends Equatable {
  /// User ID
  final String id;
  
  /// User email
  final String email;
  
  /// User display name
  final String displayName;
  
  /// User photo URL
  final String? photoUrl;
  
  /// Whether the email is verified
  final bool emailVerified;
  
  /// Creation date
  final DateTime createdAt;
  
  /// Membership plan type
  final MembershipPlanType planType;
  
  /// Membership plan expiration date
  final DateTime? planExpiresAt;
  
  /// Membership plan ID
  final String? membershipPlan;
  
  /// Whether membership is active
  final bool isMembershipActive;
  
  /// Number of poems created
  final int poemsCreated;
  
  /// Number of favorites
  final int favorites;
  
  /// Number of shares
  final int shares;
  
  /// Constructor
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.emailVerified,
    required this.createdAt,
    required this.planType,
    this.planExpiresAt,
    this.membershipPlan,
    this.isMembershipActive = false,
    this.poemsCreated = 0,
    this.favorites = 0,
    this.shares = 0,
  });
  
  /// Get user name (alias for displayName)
  String get name => displayName;
  
  /// Get membership expiration date (alias for planExpiresAt)
  DateTime? get membershipExpiresAt => planExpiresAt;
  
  /// Get user initials
  String get initials {
    if (displayName.isEmpty) {
      return '';
    }
    
    final parts = displayName.split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
  
  /// Create a copy with modified properties
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
    MembershipPlanType? planType,
    DateTime? planExpiresAt,
    String? membershipPlan,
    bool? isMembershipActive,
    int? poemsCreated,
    int? favorites,
    int? shares,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      planType: planType ?? this.planType,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      membershipPlan: membershipPlan ?? this.membershipPlan,
      isMembershipActive: isMembershipActive ?? this.isMembershipActive,
      poemsCreated: poemsCreated ?? this.poemsCreated,
      favorites: favorites ?? this.favorites,
      shares: shares ?? this.shares,
    );
  }
  
  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
      emailVerified: json['email_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      planType: MembershipPlanType.values.firstWhere(
        (e) => e.name == json['plan_type'],
        orElse: () => MembershipPlanType.free,
      ),
      planExpiresAt: json['plan_expires_at'] != null
          ? DateTime.parse(json['plan_expires_at'] as String)
          : null,
      membershipPlan: json['membership_plan'] as String?,
      isMembershipActive: json['is_membership_active'] as bool? ?? false,
      poemsCreated: json['poems_created'] as int? ?? 0,
      favorites: json['favorites'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'plan_type': planType.name,
      'plan_expires_at': planExpiresAt?.toIso8601String(),
      'membership_plan': membershipPlan,
      'is_membership_active': isMembershipActive,
      'poems_created': poemsCreated,
      'favorites': favorites,
      'shares': shares,
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    emailVerified,
    createdAt,
    planType,
    planExpiresAt,
    membershipPlan,
    isMembershipActive,
    poemsCreated,
    favorites,
    shares,
  ];
}
