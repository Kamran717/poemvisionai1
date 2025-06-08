import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/profile/domain/models/user_profile.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';

/// Profile service
class ProfileService {
  /// API client
  final ApiClient _apiClient;
  
  /// Constructor
  ProfileService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  
  /// Get user profile
  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _apiClient.getProfile();
      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update user profile
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
    String? bio,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (bio != null) data['bio'] = bio;
      
      final response = await _apiClient.updateProfile(
        name: name,
        email: email,
        bio: bio,
      );
      
      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _apiClient.post(
        '/users/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get available membership plans
  Future<List<MembershipPlan>> getMembershipPlans() async {
    try {
      final response = await _apiClient.getMembershipPlans();
      final List<dynamic> plans = response['plans'] as List<dynamic>;
      
      return plans
          .map((plan) => MembershipPlan.fromJson(plan as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Subscribe to a membership plan
  Future<bool> subscribeToPlan(String planId) async {
    try {
      await _apiClient.subscribeToPlan(planId);
      return true;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cancel membership subscription
  Future<bool> cancelSubscription() async {
    try {
      await _apiClient.cancelSubscription();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
