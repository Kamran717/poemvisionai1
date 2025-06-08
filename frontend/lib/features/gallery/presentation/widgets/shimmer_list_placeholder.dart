import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer effect for loading list items
class ShimmerListPlaceholder extends StatelessWidget {
  /// Number of items to show
  final int itemCount;

  /// Constructor
  const ShimmerListPlaceholder({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
  }
}
