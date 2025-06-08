import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Shimmer loading placeholder
class ShimmerLoadingPlaceholder extends StatelessWidget {
  /// Width of the placeholder
  final double? width;
  
  /// Height of the placeholder
  final double? height;
  
  /// Border radius of the placeholder
  final double borderRadius;
  
  /// Whether the placeholder is circular
  final bool isCircular;
  
  /// Constructor
  const ShimmerLoadingPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for a text
class ShimmerTextPlaceholder extends StatelessWidget {
  /// Width of the placeholder
  final double? width;
  
  /// Height of the placeholder
  final double height;
  
  /// Constructor
  const ShimmerTextPlaceholder({
    super.key,
    this.width,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingPlaceholder(
      width: width,
      height: height,
      borderRadius: 4,
    );
  }
}

/// Shimmer loading placeholder for a list item
class ShimmerListItemPlaceholder extends StatelessWidget {
  /// Constructor
  const ShimmerListItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoadingPlaceholder(
            width: 60,
            height: 60,
            isCircular: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerTextPlaceholder(width: 140),
                const SizedBox(height: 8),
                const ShimmerTextPlaceholder(width: 200),
                const SizedBox(height: 8),
                ShimmerTextPlaceholder(width: MediaQuery.of(context).size.width * 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for a card
class ShimmerCardPlaceholder extends StatelessWidget {
  /// Width of the placeholder
  final double? width;
  
  /// Height of the placeholder
  final double height;
  
  /// Constructor
  const ShimmerCardPlaceholder({
    super.key,
    this.width,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ShimmerLoadingPlaceholder(
        width: width,
        height: height,
        borderRadius: 12,
      ),
    );
  }
}

/// Shimmer loading placeholder for a grid item
class ShimmerGridItemPlaceholder extends StatelessWidget {
  /// Constructor
  const ShimmerGridItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerLoadingPlaceholder(
          width: double.infinity,
          height: 120,
          borderRadius: 8,
        ),
        const SizedBox(height: 8),
        const ShimmerTextPlaceholder(width: 100),
        const SizedBox(height: 4),
        const ShimmerTextPlaceholder(width: 80),
      ],
    );
  }
}

/// Shimmer loading placeholder for a profile
class ShimmerProfilePlaceholder extends StatelessWidget {
  /// Constructor
  const ShimmerProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerLoadingPlaceholder(
          width: 100,
          height: 100,
          isCircular: true,
        ),
        const SizedBox(height: 16),
        const ShimmerTextPlaceholder(width: 150),
        const SizedBox(height: 8),
        const ShimmerTextPlaceholder(width: 120),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const ShimmerTextPlaceholder(width: double.infinity),
              const SizedBox(height: 12),
              const ShimmerTextPlaceholder(width: double.infinity),
              const SizedBox(height: 12),
              const ShimmerTextPlaceholder(width: double.infinity),
            ],
          ),
        ),
      ],
    );
  }
}
