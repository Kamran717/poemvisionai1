class Membership {
  final int id;
  final String name;
  final double price;
  final String? description;
  final Map<String, dynamic>? features;
  final int maxPoemTypes;
  final int maxFrameTypes;
  final String? stripePriceId;
  final int maxSavedPoems;
  final bool hasGallery;
  final DateTime createdAt;

  Membership({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.features,
    required this.maxPoemTypes,
    required this.maxFrameTypes,
    this.stripePriceId,
    required this.maxSavedPoems,
    this.hasGallery = false,
    required this.createdAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      description: json['description'],
      features: json['features'],
      maxPoemTypes: json['max_poem_types'],
      maxFrameTypes: json['max_frame_types'],
      stripePriceId: json['stripe_price_id'],
      maxSavedPoems: json['max_saved_poems'],
      hasGallery: json['has_gallery'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'features': features,
      'max_poem_types': maxPoemTypes,
      'max_frame_types': maxFrameTypes,
      'stripe_price_id': stripePriceId,
      'max_saved_poems': maxSavedPoems,
      'has_gallery': hasGallery,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
