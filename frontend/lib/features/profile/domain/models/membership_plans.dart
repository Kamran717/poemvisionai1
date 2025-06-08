import 'package:frontend/features/profile/domain/models/membership_plan.dart';

/// Collection of membership plans
class MembershipPlans {
  /// Private constructor to prevent instantiation
  MembershipPlans._();
  
  /// Free plan
  static MembershipPlan get free => MembershipPlan.free;
  
  /// Basic plan
  static MembershipPlan get basic => MembershipPlan.basic;
  
  /// Premium plan
  static MembershipPlan get premium => MembershipPlan.premium;
  
  /// Pro plan
  static MembershipPlan get pro => MembershipPlan.pro;
  
  /// All available plans
  static List<MembershipPlan> get all => MembershipPlan.plans;
  
  /// Get plan by type
  static MembershipPlan getPlanByType(MembershipPlanType type) {
    switch (type) {
      case MembershipPlanType.free:
        return free;
      case MembershipPlanType.basic:
        return basic;
      case MembershipPlanType.premium:
        return premium;
      case MembershipPlanType.pro:
        return pro;
    }
  }
  
  /// Get plan by ID
  static MembershipPlan? getPlanById(String id) {
    return all.where((plan) => plan.id == id).firstOrNull;
  }
}
