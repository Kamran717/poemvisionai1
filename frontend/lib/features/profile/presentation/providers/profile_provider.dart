import 'package:flutter/foundation.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';
import 'package:frontend/features/profile/domain/models/membership_plans.dart';
import 'package:frontend/features/profile/domain/models/user_profile.dart';

/// Provider for profile-related data
class ProfileProvider extends ChangeNotifier {
  /// User profile
  UserProfile? _profile;
  
  /// Current membership plan
  MembershipPlan? _currentPlan;
  
  /// Available membership plans
  List<MembershipPlan> _availablePlans = MembershipPlans.all;
  
  /// Usage statistics
  Map<String, dynamic> _usageStats = {};
  
  /// Theme preference (light/dark/system)
  String _themePreference = 'system';
  
  /// Notification preference
  bool _notificationPreference = true;
  
  /// Whether profile is loading
  bool _isLoading = false;
  
  /// Whether there is an error
  bool _hasError = false;
  
  /// Error message
  String _errorMessage = '';
  
  /// Get user profile
  UserProfile? get profile => _profile;
  
  /// Get current membership plan
  MembershipPlan? get currentPlan => _currentPlan;
  
  /// Get available membership plans
  List<MembershipPlan> get availablePlans => _availablePlans;
  
  /// Get usage statistics
  Map<String, dynamic> get usageStats => _usageStats;
  
  /// Get theme preference
  String get themePreference => _themePreference;
  
  /// Get notification preference
  bool get notificationPreference => _notificationPreference;
  
  /// Get loading state
  bool get isLoading => _isLoading;
  
  /// Get error state
  bool get hasError => _hasError;
  
  /// Get error message
  String get errorMessage => _errorMessage;
  
  /// Check if user has premium
  bool get hasPremium => _profile?.planType != MembershipPlanType.free;
  
  /// Get membership status text
  String get membershipStatusText {
    if (_profile == null) {
      return 'Free';
    }
    
    switch (_profile!.planType) {
      case MembershipPlanType.free:
        return 'Free Plan';
      case MembershipPlanType.basic:
        return 'Basic Plan';
      case MembershipPlanType.premium:
        return 'Premium Plan';
      case MembershipPlanType.pro:
        return 'Pro Plan';
    }
  }
  
  /// Initialize auth state
  Future<void> initializeProfileState() async {
    _setLoading(true);
    
    try {
      await fetchUserProfile();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize profile: $e');
    }
  }
  
  /// Fetch user profile
  Future<void> fetchUserProfile() async {
    _setLoading(true);
    
    try {
      // TODO: Implement API call
      // Mock data for now
      _profile = UserProfile(
        id: 'user123',
        email: 'user@example.com',
        displayName: 'John Doe',
        photoUrl: null,
        emailVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        planType: MembershipPlanType.free,
        planExpiresAt: null,
        membershipPlan: 'free',
        isMembershipActive: false,
      );
      
      _currentPlan = MembershipPlans.getPlanByType(_profile!.planType);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch profile: $e');
    }
  }
  
  /// Load profile
  Future<void> loadProfile() async {
    await fetchUserProfile();
  }
  
  /// Load usage statistics
  Future<void> loadUsageStats() async {
    _setLoading(true);
    
    try {
      // TODO: Implement API call
      // Mock data for now
      _usageStats = {
        'poems_generated': 15,
        'favorites': 5,
        'shares': 3,
        'storage_used': 25, // in MB
        'storage_limit': 100, // in MB
      };
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load usage stats: $e');
    }
  }
  
  /// Load membership plans
  Future<void> loadMembershipPlans() async {
    _setLoading(true);
    
    try {
      // TODO: Implement API call
      // Using static data for now
      _availablePlans = MembershipPlans.all;
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load membership plans: $e');
    }
  }
  
  /// Update profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_profile == null) {
      return false;
    }
    
    _setLoading(true);
    
    try {
      // TODO: Implement API call
      // Update local profile
      _profile = _profile!.copyWith(
        displayName: displayName ?? _profile!.displayName,
        photoUrl: photoUrl ?? _profile!.photoUrl,
      );
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    }
  }
  
  /// Send verification email
  Future<bool> sendVerificationEmail() async {
    if (_profile == null) {
      return false;
    }
    
    _setLoading(true);
    
    try {
      // TODO: Implement API call
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send verification email: $e');
      return false;
    }
  }
  
  /// Delete account
  Future<bool> deleteAccount({required String password}) async {
    if (_profile == null) {
      return false;
    }
    
    _setLoading(true);
    
    try {
      // TODO: Implement API call with password
      // In a real implementation, the password would be verified on the server
      
      _profile = null;
      _currentPlan = null;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    }
  }
  
  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    if (_profile == null) {
      return false;
    }
    
    _setLoading(true);
    
    try {
      // TODO: Implement API call
      // Update local profile
      _profile = _profile!.copyWith(
        planType: MembershipPlanType.free,
        isMembershipActive: false,
        membershipPlan: 'free',
        planExpiresAt: null,
      );
      
      _currentPlan = MembershipPlans.free;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to cancel subscription: $e');
      return false;
    }
  }
  
  /// Get theme preference
  Future<String> getThemePreference() async {
    // TODO: Implement storage retrieval
    return _themePreference;
  }
  
  /// Get notification preference
  Future<bool> getNotificationPreference() async {
    // TODO: Implement storage retrieval
    return _notificationPreference;
  }
  
  /// Update preferences
  Future<bool> updatePreferences({
    String? themePreference,
    bool? notificationPreference,
  }) async {
    _setLoading(true);
    
    try {
      // TODO: Implement storage update
      if (themePreference != null) {
        _themePreference = themePreference;
      }
      
      if (notificationPreference != null) {
        _notificationPreference = notificationPreference;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update preferences: $e');
      return false;
    }
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _hasError = false;
      _errorMessage = '';
    }
    notifyListeners();
  }
  
  /// Set error state
  void _setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
}
