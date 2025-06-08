import 'package:flutter/foundation.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/profile/domain/models/user_profile.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';
import 'package:frontend/features/profile/domain/services/profile_service.dart';

/// Provider for profile functionality
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;
  
  // User profile
  UserProfile? _profile;
  UserProfile? get profile => _profile;
  
  // Membership plans
  List<MembershipPlan> _availablePlans = [];
  List<MembershipPlan> get availablePlans => _availablePlans;
  
  // Current plan
  MembershipPlan? _currentPlan;
  MembershipPlan? get currentPlan => _currentPlan;
  
  // User statistics
  Map<String, dynamic>? _usageStats;
  Map<String, dynamic>? get usageStats => _usageStats;
  
  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  ProfileProvider(this._profileService);
  
  /// Load user profile
  Future<void> loadProfile() async {
    if (_isLoading) return;
    
    try {
      _setLoading(true);
      
      _profile = await _profileService.getUserProfile();
      await _loadCurrentPlan();
      
      _setLoading(false);
    } catch (e) {
      AppLogger.e('Error loading profile', e);
      _setError('Failed to load profile');
    }
  }
  
  /// Load user's usage statistics
  Future<void> loadUsageStats() async {
    try {
      _usageStats = await _profileService.getUsageStats();
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error loading usage stats', e);
      // Don't set error, just log it
    }
  }
  
  /// Load available membership plans
  Future<void> loadMembershipPlans() async {
    try {
      _availablePlans = await _profileService.getMembershipPlans();
      
      if (_profile != null) {
        await _loadCurrentPlan();
      }
      
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error loading membership plans', e);
      // Use default plans if API fails
      _availablePlans = MembershipPlans.getAll();
      
      if (_profile != null) {
        await _loadCurrentPlan();
      }
      
      notifyListeners();
    }
  }
  
  /// Helper to load current plan
  Future<void> _loadCurrentPlan() async {
    if (_profile == null) return;
    
    if (_availablePlans.isEmpty) {
      await loadMembershipPlans();
    }
    
    _currentPlan = _availablePlans.firstWhere(
      (plan) => plan.id == _profile!.membershipPlan,
      orElse: () => MembershipPlans.free,
    );
    
    notifyListeners();
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    required String displayName,
  }) async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final updatedProfile = await _profileService.updateProfile(
        displayName: displayName,
      );
      
      _profile = updatedProfile;
      _isUpdating = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      AppLogger.e('Error updating profile', e);
      _setError('Failed to update profile');
      return false;
    }
  }
  
  /// Update user profile photo
  Future<bool> updateProfilePhoto(String photoUrl) async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final updatedProfile = await _profileService.updateProfile(
        photoUrl: photoUrl,
      );
      
      _profile = updatedProfile;
      _isUpdating = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      AppLogger.e('Error updating profile photo', e);
      _setError('Failed to update profile photo');
      return false;
    }
  }
  
  /// Update user preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final updatedProfile = await _profileService.updatePreferences(preferences);
      
      _profile = updatedProfile;
      _isUpdating = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      AppLogger.e('Error updating preferences', e);
      _setError('Failed to update preferences');
      return false;
    }
  }
  
  /// Subscribe to a membership plan
  Future<bool> subscribeToPlan({
    required String planId,
    required bool isYearly,
    required String paymentMethodId,
  }) async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final updatedProfile = await _profileService.subscribeToPlan(
        planId: planId,
        isYearly: isYearly,
        paymentMethodId: paymentMethodId,
      );
      
      _profile = updatedProfile;
      await _loadCurrentPlan();
      
      _isUpdating = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      AppLogger.e('Error subscribing to plan', e);
      _setError('Failed to subscribe to plan');
      return false;
    }
  }
  
  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final updatedProfile = await _profileService.cancelSubscription();
      
      _profile = updatedProfile;
      await _loadCurrentPlan();
      
      _isUpdating = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      AppLogger.e('Error cancelling subscription', e);
      _setError('Failed to cancel subscription');
      return false;
    }
  }
  
  /// Send email verification
  Future<bool> sendVerificationEmail() async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final success = await _profileService.sendVerificationEmail();
      
      _isUpdating = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      AppLogger.e('Error sending verification email', e);
      _setError('Failed to send verification email');
      return false;
    }
  }
  
  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final success = await _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _isUpdating = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      AppLogger.e('Error changing password', e);
      _setError('Failed to change password');
      return false;
    }
  }
  
  /// Delete account
  Future<bool> deleteAccount({
    required String password,
  }) async {
    if (_isUpdating) return false;
    
    try {
      _isUpdating = true;
      _clearError();
      notifyListeners();
      
      final success = await _profileService.deleteAccount(
        password: password,
      );
      
      if (success) {
        // Clear local profile data on successful deletion
        _profile = null;
        _currentPlan = null;
      }
      
      _isUpdating = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      AppLogger.e('Error deleting account', e);
      _setError('Failed to delete account');
      return false;
    }
  }
  
  /// Check if user has premium features
  bool get hasPremium => 
      _profile != null && 
      _profile!.isPremium && 
      _profile!.isMembershipActive;
  
  /// Get user's membership status text
  String get membershipStatusText {
    if (_profile == null) return 'Unknown';
    
    if (_profile!.membershipPlan == 'free') {
      return 'Free Plan';
    }
    
    if (_profile!.membershipExpiresAt == null) {
      return 'Inactive Subscription';
    }
    
    if (_profile!.isMembershipActive) {
      return '${_profile!.membershipPlan.capitalize()} Plan (Active)';
    } else {
      return '${_profile!.membershipPlan.capitalize()} Plan (Expired)';
    }
  }
  
  /// Get the current theme preference
  String getThemePreference() {
    if (_profile?.preferences == null) return 'system';
    return _profile!.preferences!['theme'] as String? ?? 'system';
  }
  
  /// Get notification preferences
  bool getNotificationPreference() {
    if (_profile?.preferences == null) return true;
    return _profile!.preferences!['notifications'] as bool? ?? true;
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _isUpdating = false;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }
}
