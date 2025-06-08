import 'package:flutter/foundation.dart';
import 'package:frontend/features/profile/domain/models/user_profile.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';
import 'package:frontend/features/profile/domain/services/profile_service.dart';

/// Profile provider
class ProfileProvider extends ChangeNotifier {
  /// Profile service
  final ProfileService _profileService;
  
  /// User profile
  UserProfile? _userProfile;
  
  /// Available membership plans
  List<MembershipPlan> _membershipPlans = [];
  
  /// Loading state
  bool _isLoading = false;
  
  /// Error message
  String? _errorMessage;
  
  /// Constructor
  ProfileProvider({
    required ProfileService profileService,
  }) : _profileService = profileService;
  
  /// Get user profile
  UserProfile? get userProfile => _userProfile;
  
  /// Get available membership plans
  List<MembershipPlan> get membershipPlans => _membershipPlans;
  
  /// Get loading state
  bool get isLoading => _isLoading;
  
  /// Get error message
  String? get errorMessage => _errorMessage;
  
  /// Fetch user profile from API
  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final profile = await _profileService.getUserProfile();
      _userProfile = profile;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? bio,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedProfile = await _profileService.updateProfile(
        name: name,
        email: email,
        bio: bio,
      );
      
      _userProfile = updatedProfile;
      _errorMessage = null;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Fetch available membership plans
  Future<void> fetchMembershipPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final plans = await _profileService.getMembershipPlans();
      _membershipPlans = plans;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Subscribe to a membership plan
  Future<bool> subscribeToPlan(String planId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _profileService.subscribeToPlan(planId);
      if (success) {
        // Refresh user profile to get updated membership status
        await fetchUserProfile();
      }
      
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Cancel membership subscription
  Future<bool> cancelSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _profileService.cancelSubscription();
      if (success) {
        // Refresh user profile to get updated membership status
        await fetchUserProfile();
      }
      
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Clear user profile (used for logout)
  void clearProfile() {
    _userProfile = null;
    _membershipPlans = [];
    notifyListeners();
  }
}
