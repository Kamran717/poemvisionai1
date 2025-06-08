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

/// Shimmer loading placeholder for a list or grid of items
class ShimmerListPlaceholder extends StatelessWidget {
  /// Whether to show as grid or list
  final bool isGrid;
  
  /// Number of cross axis items for grid
  final int gridCrossAxisCount;
  
  /// Aspect ratio for grid items
  final double itemAspectRatio;
  
  /// Number of items to show
  final int itemCount;
  
  /// Constructor
  const ShimmerListPlaceholder({
    super.key,
    this.isGrid = false,
    this.gridCrossAxisCount = 2,
    this.itemAspectRatio = 0.75,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCrossAxisCount,
          childAspectRatio: itemAspectRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    Container(
                      height: 120,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    // Title placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: 150,
                        height: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Content placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Content placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: 200,
                        height: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title placeholder
                        Container(
                          width: 180,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        // Content placeholder
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        // Content placeholder
                        Container(
                          width: 150,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        // Info placeholder
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 90,
                              height: 10,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action placeholder
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
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
