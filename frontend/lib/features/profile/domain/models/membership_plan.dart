import 'package:equatable/equatable.dart';

/// Membership plan model
class MembershipPlan extends Equatable {
  /// Unique ID
  final String id;
  
  /// Plan name
  final String name;
  
  /// Plan description
  final String description;
  
  /// Monthly price in cents
  final int pricePerMonth;
  
  /// Yearly price in cents
  final int pricePerYear;
  
  /// Benefits list
  final List<String> benefits;
  
  /// Whether it has unlimited generations
  final bool unlimitedGenerations;
  
  /// Monthly generation quota
  final int generationsPerMonth;
  
  /// Whether custom styles are allowed
  final bool allowCustomStyles;
  
  /// Whether custom prompts are allowed
  final bool allowCustomPrompts;
  
  /// Whether HD export is allowed
  final bool allowHdExport;
  
  /// Color for display
  final String? colorHex;
  
  /// Is this the recommended plan
  final bool isRecommended;
  
  /// Sort order
  final int order;
  
  /// Constructor
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerMonth,
    required this.pricePerYear,
    required this.benefits,
    this.unlimitedGenerations = false,
    this.generationsPerMonth = 5,
    this.allowCustomStyles = false,
    this.allowCustomPrompts = false,
    this.allowHdExport = false,
    this.colorHex,
    this.isRecommended = false,
    this.order = 0,
  });
  
  /// Create from JSON
  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      pricePerMonth: json['price_per_month'] as int,
      pricePerYear: json['price_per_year'] as int,
      benefits: List<String>.from(json['benefits'] as List),
      unlimitedGenerations: json['unlimited_generations'] as bool? ?? false,
      generationsPerMonth: json['generations_per_month'] as int? ?? 5,
      allowCustomStyles: json['allow_custom_styles'] as bool? ?? false,
      allowCustomPrompts: json['allow_custom_prompts'] as bool? ?? false,
      allowHdExport: json['allow_hd_export'] as bool? ?? false,
      colorHex: json['color_hex'] as String?,
      isRecommended: json['is_recommended'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_per_month': pricePerMonth,
      'price_per_year': pricePerYear,
      'benefits': benefits,
      'unlimited_generations': unlimitedGenerations,
      'generations_per_month': generationsPerMonth,
      'allow_custom_styles': allowCustomStyles,
      'allow_custom_prompts': allowCustomPrompts,
      'allow_hd_export': allowHdExport,
      'color_hex': colorHex,
      'is_recommended': isRecommended,
      'order': order,
    };
  }
  
  /// Format monthly price to display format
  String get formattedMonthlyPrice {
    final dollars = pricePerMonth / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }
  
  /// Format yearly price to display format
  String get formattedYearlyPrice {
    final dollars = pricePerYear / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }
  
  /// Create a copy with some fields changed
  MembershipPlan copyWith({
    String? id,
    String? name,
    String? description,
    int? pricePerMonth,
    int? pricePerYear,
    List<String>? benefits,
    bool? unlimitedGenerations,
    int? generationsPerMonth,
    bool? allowCustomStyles,
    bool? allowCustomPrompts,
    bool? allowHdExport,
    String? colorHex,
    bool? isRecommended,
    int? order,
  }) {
    return MembershipPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      pricePerYear: pricePerYear ?? this.pricePerYear,
      benefits: benefits ?? this.benefits,
      unlimitedGenerations: unlimitedGenerations ?? this.unlimitedGenerations,
      generationsPerMonth: generationsPerMonth ?? this.generationsPerMonth,
      allowCustomStyles: allowCustomStyles ?? this.allowCustomStyles,
      allowCustomPrompts: allowCustomPrompts ?? this.allowCustomPrompts,
      allowHdExport: allowHdExport ?? this.allowHdExport,
      colorHex: colorHex ?? this.colorHex,
      isRecommended: isRecommended ?? this.isRecommended,
      order: order ?? this.order,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    description,
    pricePerMonth,
    pricePerYear,
    benefits,
    unlimitedGenerations,
    generationsPerMonth,
    allowCustomStyles,
    allowCustomPrompts,
    allowHdExport,
    colorHex,
    isRecommended,
    order,
  ];
}
