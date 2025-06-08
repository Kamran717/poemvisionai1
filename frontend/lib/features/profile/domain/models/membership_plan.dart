import 'package:equatable/equatable.dart';

/// Membership plan types
enum MembershipPlanType {
  /// Free plan
  free,
  
  /// Basic plan
  basic,
  
  /// Premium plan
  premium,
  
  /// Pro plan
  pro,
}

/// Membership plan model
class MembershipPlan extends Equatable {
  /// Plan ID
  final String id;
  
  /// Plan name
  final String name;
  
  /// Plan description
  final String description;
  
  /// Monthly price
  final double monthlyPrice;
  
  /// Yearly price
  final double yearlyPrice;
  
  /// Plan type
  final MembershipPlanType type;
  
  /// Plan features
  final List<String> features;
  
  /// Whether this plan is marked as popular
  final bool isPopular;
  
  /// Constructor
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.type,
    required this.features,
    this.isPopular = false,
  });
  
  /// Yearly price per month
  double get yearlyPricePerMonth => yearlyPrice / 12;
  
  /// Yearly discount percentage
  int get yearlyDiscountPercentage => 
    ((1 - (yearlyPrice / 12) / monthlyPrice) * 100).round();
  
  /// Create from JSON
  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      monthlyPrice: (json['monthly_price'] as num).toDouble(),
      yearlyPrice: (json['yearly_price'] as num).toDouble(),
      type: MembershipPlanType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MembershipPlanType.free,
      ),
      features: List<String>.from(json['features'] as List),
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthly_price': monthlyPrice,
      'yearly_price': yearlyPrice,
      'type': type.name,
      'features': features,
      'is_popular': isPopular,
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    description,
    monthlyPrice,
    yearlyPrice,
    type,
    features,
    isPopular,
  ];
  
  /// Free plan
  static MembershipPlan get free => const MembershipPlan(
    id: 'free',
    name: 'Free',
    description: 'Basic features for casual users',
    monthlyPrice: 0,
    yearlyPrice: 0,
    type: MembershipPlanType.free,
    features: [
      'Generate up to 5 poems per month',
      'Basic frames',
      'Standard resolution',
      'Community support',
    ],
  );
  
  /// Basic plan
  static MembershipPlan get basic => const MembershipPlan(
    id: 'basic',
    name: 'Basic',
    description: 'More features for regular users',
    monthlyPrice: 4.99,
    yearlyPrice: 49.99,
    type: MembershipPlanType.basic,
    features: [
      'Generate up to 20 poems per month',
      'All frames',
      'High resolution',
      'Email support',
      'No watermarks',
    ],
  );
  
  /// Premium plan
  static MembershipPlan get premium => const MembershipPlan(
    id: 'premium',
    name: 'Premium',
    description: 'Enhanced features for enthusiasts',
    monthlyPrice: 9.99,
    yearlyPrice: 99.99,
    type: MembershipPlanType.premium,
    isPopular: true,
    features: [
      'Generate up to 100 poems per month',
      'All frames plus exclusives',
      'Ultra-high resolution',
      'Priority email support',
      'No watermarks',
      'Advanced customization options',
    ],
  );
  
  /// Pro plan
  static MembershipPlan get pro => const MembershipPlan(
    id: 'pro',
    name: 'Pro',
    description: 'Ultimate features for professionals',
    monthlyPrice: 19.99,
    yearlyPrice: 199.99,
    type: MembershipPlanType.pro,
    features: [
      'Unlimited poems generation',
      'All frames plus exclusives',
      'Ultra-high resolution',
      'Priority support with dedicated account manager',
      'No watermarks',
      'Advanced customization options',
      'API access',
      'Commercial usage rights',
    ],
  );
  
  /// All available plans
  static List<MembershipPlan> get plans => [
    free,
    basic,
    premium,
    pro,
  ];
}
