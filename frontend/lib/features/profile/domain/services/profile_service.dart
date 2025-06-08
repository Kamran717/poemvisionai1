import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/profile/domain/models/user_profile.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';

/// Service for handling profile operations
class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  /// Get the current user's profile
  Future<UserProfile> getUserProfile() async {
    try {
      AppLogger.d('Getting user profile');
      
      final response = await _apiClient.get('/api/profile');
      
      if (response.isSuccess && response.data != null) {
        final profileData = response.data!;
        return UserProfile.fromJson(profileData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to get user profile');
      }
    } catch (e) {
      AppLogger.e('Error getting user profile', e);
      
      // During development, return mock data if API call fails
      if (e.toString().contains('Failed to get user profile')) {
        return _getMockUserProfile();
      }
      
      rethrow;
    }
  }

  /// Update the user's profile
  Future<UserProfile> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      AppLogger.d('Updating user profile');
      
      final response = await _apiClient.patch(
        '/api/profile',
        data: {
          if (displayName != null) 'display_name': displayName,
          if (photoUrl != null) 'photo_url': photoUrl,
        },
      );
      
      if (response.isSuccess && response.data != null) {
        final updatedProfileData = response.data!;
        return UserProfile.fromJson(updatedProfileData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to update profile');
      }
    } catch (e) {
      AppLogger.e('Error updating profile', e);
      rethrow;
    }
  }

  /// Update user preferences
  Future<UserProfile> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      AppLogger.d('Updating user preferences');
      
      final response = await _apiClient.patch(
        '/api/profile/preferences',
        data: preferences,
      );
      
      if (response.isSuccess && response.data != null) {
        final updatedProfileData = response.data!;
        return UserProfile.fromJson(updatedProfileData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to update preferences');
      }
    } catch (e) {
      AppLogger.e('Error updating preferences', e);
      rethrow;
    }
  }

  /// Get all available membership plans
  Future<List<MembershipPlan>> getMembershipPlans() async {
    try {
      AppLogger.d('Getting membership plans');
      
      final response = await _apiClient.get('/api/membership-plans');
      
      if (response.isSuccess && response.data != null) {
        final plansData = response.data! as List<dynamic>;
        return plansData.map((data) => MembershipPlan.fromJson(data)).toList();
      } else {
        // If API fails, return the predefined plans
        return MembershipPlans.getAll();
      }
    } catch (e) {
      AppLogger.e('Error getting membership plans', e);
      
      // Return predefined plans if API fails
      return MembershipPlans.getAll();
    }
  }

  /// Subscribe to a membership plan
  Future<UserProfile> subscribeToPlan({
    required String planId,
    required bool isYearly,
    required String paymentMethodId,
  }) async {
    try {
      AppLogger.d('Subscribing to plan: $planId (yearly: $isYearly)');
      
      final response = await _apiClient.post(
        '/api/subscribe',
        data: {
          'plan_id': planId,
          'is_yearly': isYearly,
          'payment_method_id': paymentMethodId,
        },
      );
      
      if (response.isSuccess && response.data != null) {
        final updatedProfileData = response.data!;
        return UserProfile.fromJson(updatedProfileData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to subscribe to plan');
      }
    } catch (e) {
      AppLogger.e('Error subscribing to plan', e);
      rethrow;
    }
  }

  /// Cancel the current subscription
  Future<UserProfile> cancelSubscription() async {
    try {
      AppLogger.d('Cancelling subscription');
      
      final response = await _apiClient.post('/api/cancel-subscription');
      
      if (response.isSuccess && response.data != null) {
        final updatedProfileData = response.data!;
        return UserProfile.fromJson(updatedProfileData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      AppLogger.e('Error cancelling subscription', e);
      rethrow;
    }
  }

  /// Get user's usage statistics
  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      AppLogger.d('Getting usage statistics');
      
      final response = await _apiClient.get('/api/usage-stats');
      
      if (response.isSuccess && response.data != null) {
        return response.data! as Map<String, dynamic>;
      } else {
        throw Exception(response.error?.message ?? 'Failed to get usage statistics');
      }
    } catch (e) {
      AppLogger.e('Error getting usage statistics', e);
      
      // Return mock data during development
      return {
        'poems_generated': 27,
        'images_analyzed': 35,
        'creations_shared': 12,
        'poems_by_type': {
          'haiku': 8,
          'sonnet': 5,
          'free_verse': 14,
        },
        'creations_this_month': 15,
        'creation_limit_reached': false,
        'daily_limit': 5,
        'daily_used': 3,
      };
    }
  }

  /// Send verification email
  Future<bool> sendVerificationEmail() async {
    try {
      AppLogger.d('Sending verification email');
      
      final response = await _apiClient.post('/api/send-verification-email');
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error sending verification email', e);
      rethrow;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.d('Changing password');
      
      final response = await _apiClient.post(
        '/api/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error changing password', e);
      rethrow;
    }
  }

  /// Delete account
  Future<bool> deleteAccount({
    required String password,
  }) async {
    try {
      AppLogger.d('Deleting account');
      
      final response = await _apiClient.post(
        '/api/delete-account',
        data: {
          'password': password,
        },
      );
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error deleting account', e);
      rethrow;
    }
  }

  /// Create a mock user profile for development
  UserProfile _getMockUserProfile() {
    return UserProfile(
      id: 'user_123',
      email: 'user@example.com',
      displayName: 'John Doe',
      photoUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
      membershipPlan: 'free',
      membershipExpiresAt: null,
      preferences: {
        'theme': 'light',
        'notifications': true,
        'defaultPoemType': 'free_verse',
        'defaultFrameType': 'classic',
      },
      stats: {
        'poems_generated': 27,
        'images_analyzed': 35,
        'creations_shared': 12,
      },
      emailVerified: true,
    );
  }
}
