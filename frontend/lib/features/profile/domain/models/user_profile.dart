import 'package:equatable/equatable.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';

/// User profile model
class UserProfile extends Equatable {
  /// User ID
  final String id;
  
  /// User name
  final String name;
  
  /// User email
  final String email;
  
  /// User bio
  final String? bio;
  
  /// User avatar URL
  final String? avatarUrl;
  
  /// Account creation date
  final DateTime createdAt;
  
  /// Total number of creations
  final int totalCreations;
  
  /// Number of favorite creations
  final int favoriteCreations;
  
  /// Number of shared creations
  final int sharedCreations;
  
  /// Current membership
  final MembershipPlan? currentMembership;
  
  /// Membership expiration date
  final DateTime? membershipExpiresAt;
  
  /// Monthly generation quota
  final int generationQuota;
  
  /// Remaining monthly generations
  final int remainingGenerations;
  
  /// Constructor
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    this.totalCreations = 0,
    this.favoriteCreations = 0,
    this.sharedCreations = 0,
    this.currentMembership,
    this.membershipExpiresAt,
    this.generationQuota = 5,
    this.remainingGenerations = 5,
  });
  
  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalCreations: json['total_creations'] as int? ?? 0,
      favoriteCreations: json['favorite_creations'] as int? ?? 0,
      sharedCreations: json['shared_creations'] as int? ?? 0,
      currentMembership: json['current_membership'] != null
          ? MembershipPlan.fromJson(
              json['current_membership'] as Map<String, dynamic>,
            )
          : null,
      membershipExpiresAt: json['membership_expires_at'] != null
          ? DateTime.parse(json['membership_expires_at'] as String)
          : null,
      generationQuota: json['generation_quota'] as int? ?? 5,
      remainingGenerations: json['remaining_generations'] as int? ?? 5,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'total_creations': totalCreations,
      'favorite_creations': favoriteCreations,
      'shared_creations': sharedCreations,
      'current_membership': currentMembership?.toJson(),
      'membership_expires_at': membershipExpiresAt?.toIso8601String(),
      'generation_quota': generationQuota,
      'remaining_generations': remainingGenerations,
    };
  }
  
  /// Create a copy with some fields changed
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    String? avatarUrl,
    DateTime? createdAt,
    int? totalCreations,
    int? favoriteCreations,
    int? sharedCreations,
    MembershipPlan? currentMembership,
    DateTime? membershipExpiresAt,
    int? generationQuota,
    int? remainingGenerations,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      totalCreations: totalCreations ?? this.totalCreations,
      favoriteCreations: favoriteCreations ?? this.favoriteCreations,
      sharedCreations: sharedCreations ?? this.sharedCreations,
      currentMembership: currentMembership ?? this.currentMembership,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      generationQuota: generationQuota ?? this.generationQuota,
      remainingGenerations: remainingGenerations ?? this.remainingGenerations,
    );
  }
  
  /// Check if user has premium features
  bool get hasPremium => currentMembership != null && 
      (membershipExpiresAt == null || membershipExpiresAt!.isAfter(DateTime.now()));
  
  /// Check if user can generate more poems
  bool get canGenerateMore => remainingGenerations > 0 || hasPremium;
  
  @override
  List<Object?> get props => [
    id,
    name,
    email,
    bio,
    avatarUrl,
    createdAt,
    totalCreations,
    favoriteCreations,
    sharedCreations,
    currentMembership,
    membershipExpiresAt,
    generationQuota,
    remainingGenerations,
  ];
}
