/// Model representing a membership plan
class MembershipPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final Map<String, dynamic>? metadata;
  final bool isPopular;
  
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.metadata,
    this.isPopular = false,
  });

  /// Factory constructor to create a MembershipPlan from JSON
  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      monthlyPrice: (json['monthly_price'] as num).toDouble(),
      yearlyPrice: (json['yearly_price'] as num).toDouble(),
      features: (json['features'] as List<dynamic>).map((e) => e as String).toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }

  /// Convert MembershipPlan to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthly_price': monthlyPrice,
      'yearly_price': yearlyPrice,
      'features': features,
      'metadata': metadata,
      'is_popular': isPopular,
    };
  }

  /// Calculate the discount percentage for yearly subscription
  double get yearlyDiscountPercentage {
    final monthlyTotal = monthlyPrice * 12;
    if (monthlyTotal <= 0) return 0;
    return ((monthlyTotal - yearlyPrice) / monthlyTotal * 100).roundToDouble();
  }

  /// Check if this is a free plan
  bool get isFree => monthlyPrice <= 0 && yearlyPrice <= 0;

  /// Get the yearly price per month
  double get yearlyPricePerMonth => yearlyPrice / 12;
}

/// Predefined membership plans
class MembershipPlans {
  static const MembershipPlan free = MembershipPlan(
    id: 'free',
    name: 'Free',
    description: 'Basic access to poem generation',
    monthlyPrice: 0,
    yearlyPrice: 0,
    features: [
      'Generate up to 5 poems per day',
      'Basic poem types',
      'Standard frames',
      'Save and share creations',
    ],
  );

  static const MembershipPlan pro = MembershipPlan(
    id: 'pro',
    name: 'Pro',
    description: 'Enhanced poem generation with premium features',
    monthlyPrice: 4.99,
    yearlyPrice: 49.99,
    features: [
      'Unlimited poem generation',
      'All poem types including Sonnet, Limerick, and more',
      'Premium frames collection',
      'Custom themes and styles',
      'Higher resolution exports',
      'Priority support',
    ],
    isPopular: true,
  );

  static const MembershipPlan premium = MembershipPlan(
    id: 'premium',
    name: 'Premium',
    description: 'Complete access to all features',
    monthlyPrice: 9.99,
    yearlyPrice: 99.99,
    features: [
      'Everything in Pro plan',
      'Advanced customization options',
      'Exclusive frames and styles',
      'Batch processing',
      'Commercial usage rights',
      'API access',
      'Priority support with 24-hour response',
    ],
  );

  /// Get all available membership plans
  static List<MembershipPlan> getAll() {
    return [
      free,
      pro,
      premium,
    ];
  }

  /// Get a membership plan by ID
  static MembershipPlan? getById(String id) {
    try {
      return getAll().firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get the default plan
  static MembershipPlan getDefault() {
    return free;
  }
}
