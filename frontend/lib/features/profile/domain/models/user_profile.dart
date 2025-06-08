/// Model representing a user's profile
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String membershipPlan;
  final DateTime? membershipExpiresAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? stats;
  final bool emailVerified;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.membershipPlan,
    this.membershipExpiresAt,
    this.preferences,
    this.stats,
    this.emailVerified = false,
  });

  /// Factory constructor to create a UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      membershipPlan: json['membership_plan'] as String,
      membershipExpiresAt: json['membership_expires_at'] != null
          ? DateTime.parse(json['membership_expires_at'] as String)
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
      stats: json['stats'] as Map<String, dynamic>?,
      emailVerified: json['email_verified'] as bool? ?? false,
    );
  }

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'membership_plan': membershipPlan,
      'membership_expires_at': membershipExpiresAt?.toIso8601String(),
      'preferences': preferences,
      'stats': stats,
      'email_verified': emailVerified,
    };
  }

  /// Get a copy of this UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? membershipPlan,
    DateTime? membershipExpiresAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? stats,
    bool? emailVerified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      membershipPlan: membershipPlan ?? this.membershipPlan,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  /// Check if the user has a premium membership
  bool get isPremium => membershipPlan != 'free';

  /// Check if the membership is active
  bool get isMembershipActive {
    if (membershipPlan == 'free') return true;
    if (membershipExpiresAt == null) return false;
    return membershipExpiresAt!.isAfter(DateTime.now());
  }

  /// Get the user's display name, falling back to email if not set
  String get name => displayName ?? email.split('@').first;

  /// Get the user's initials for avatar display
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final nameParts = displayName!.split(' ');
      if (nameParts.length > 1) {
        return '${nameParts.first[0]}${nameParts.last[0]}';
      }
      return displayName![0];
    }
    return email[0].toUpperCase();
  }
}
