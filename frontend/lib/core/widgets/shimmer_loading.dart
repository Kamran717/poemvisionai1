import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A widget that displays a shimmer loading effect for lists or grids
class ShimmerListPlaceholder extends StatelessWidget {
  /// Whether to display as a grid or list
  final bool isGrid;
  
  /// Number of items to display
  final int itemCount;
  
  /// Padding around the list
  final EdgeInsets padding;
  
  /// Number of columns for grid view
  final int gridCrossAxisCount;
  
  /// Aspect ratio for grid items
  final double itemAspectRatio;
  
  /// Constructor
  const ShimmerListPlaceholder({
    super.key,
    this.isGrid = false,
    this.itemCount = 10,
    this.padding = const EdgeInsets.all(16.0),
    this.gridCrossAxisCount = 2,
    this.itemAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: padding,
        child: isGrid
            ? _buildGridPlaceholder()
            : _buildListPlaceholder(),
      ),
    );
  }
  
  /// Build grid placeholder
  Widget _buildGridPlaceholder() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCrossAxisCount,
        childAspectRatio: itemAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => _buildGridItem(),
    );
  }
  
  /// Build list placeholder
  Widget _buildListPlaceholder() {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (_, __) => _buildListItem(),
    );
  }
  
  /// Build a grid item placeholder
  Widget _buildGridItem() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
            
            // Content area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    
                    // Content
                    Container(
                      width: double.infinity,
                      height: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity * 0.7,
                      height: 10,
                      color: Colors.white,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Date
                    Container(
                      width: 80,
                      height: 8,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a list item placeholder
  Widget _buildListItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                
                // Description
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                
                // Tags and date
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a shimmer loading effect for a card
class ShimmerCardPlaceholder extends StatelessWidget {
  /// Height of the card
  final double height;
  
  /// Width of the card
  final double? width;
  
  /// Border radius of the card
  final double borderRadius;
  
  /// Constructor
  const ShimmerCardPlaceholder({
    super.key,
    this.height = 200,
    this.width,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A widget that displays a shimmer loading effect for text
class ShimmerTextPlaceholder extends StatelessWidget {
  /// Width of the text
  final double? width;
  
  /// Height of the text
  final double height;
  
  /// Border radius of the text
  final double borderRadius;
  
  /// Constructor
  const ShimmerTextPlaceholder({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 2,
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
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A widget that displays a shimmer loading effect for a profile
class ShimmerProfilePlaceholder extends StatelessWidget {
  /// Constructor
  const ShimmerProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Container(
            width: 150,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          
          // Email
          Container(
            width: 200,
            height: 14,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Buttons
          Container(
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
