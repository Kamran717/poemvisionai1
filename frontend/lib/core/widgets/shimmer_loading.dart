import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer loading widget for creating skeleton UI
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final Widget? placeholder;
  
  /// Constructor for ShimmerLoading
  /// 
  /// [isLoading] - Whether to show the shimmer effect
  /// [child] - The widget to display when not loading
  /// [placeholder] - Optional custom placeholder to use instead of the child when loading
  /// [baseColor] - The base color of the shimmer effect
  /// [highlightColor] - The highlight color of the shimmer effect
  /// [duration] - The duration of the shimmer effect
  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.placeholder,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }
    
    // Use theme colors if not provided
    final theme = Theme.of(context);
    final effectBaseColor = baseColor ?? theme.colorScheme.surface;
    final effectHighlightColor = highlightColor ?? theme.colorScheme.surfaceVariant;
    
    // Use the child as placeholder if no custom placeholder is provided
    final Widget loadingChild = placeholder ?? _buildChildPlaceholder(child);
    
    return Shimmer.fromColors(
      baseColor: effectBaseColor,
      highlightColor: effectHighlightColor,
      period: duration,
      child: loadingChild,
    );
  }
  
  /// Builds a placeholder based on the child's type
  Widget _buildChildPlaceholder(Widget child) {
    // Replace text with rectangles
    if (child is Text) {
      return Container(
        width: double.infinity,
        height: 16,
        color: Colors.white,
      );
    }
    
    // Replace images with rectangles
    if (child is Image || child is CircleAvatar) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.white,
      );
    }
    
    // Pass through the child for other widgets
    return _makeChildOpaque(child);
  }
  
  /// Makes a child widget opaque for the shimmer effect
  Widget _makeChildOpaque(Widget child) {
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        ),
        child: child,
      ),
    );
  }
}

/// A list of shimmer placeholders for list/grid views
class ShimmerListPlaceholder extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool isGrid;
  final int? gridCrossAxisCount;
  final double? itemAspectRatio;
  final EdgeInsetsGeometry padding;
  final Color? baseColor;
  final Color? highlightColor;
  
  const ShimmerListPlaceholder({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 80,
    this.isGrid = false,
    this.gridCrossAxisCount = 2,
    this.itemAspectRatio = 0.75,
    this.padding = const EdgeInsets.all(16.0),
    this.baseColor,
    this.highlightColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectBaseColor = baseColor ?? theme.colorScheme.surface;
    final effectHighlightColor = highlightColor ?? theme.colorScheme.surfaceVariant;
    
    return Shimmer.fromColors(
      baseColor: effectBaseColor,
      highlightColor: effectHighlightColor,
      child: Padding(
        padding: padding,
        child: isGrid
            ? _buildGridPlaceholder()
            : _buildListPlaceholder(),
      ),
    );
  }
  
  Widget _buildListPlaceholder() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
  
  Widget _buildGridPlaceholder() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCrossAxisCount!,
        childAspectRatio: itemAspectRatio!,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// A shimmer placeholder for details screens
class ShimmerDetailPlaceholder extends StatelessWidget {
  final Color? baseColor;
  final Color? highlightColor;
  
  const ShimmerDetailPlaceholder({
    super.key,
    this.baseColor,
    this.highlightColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectBaseColor = baseColor ?? theme.colorScheme.surface;
    final effectHighlightColor = highlightColor ?? theme.colorScheme.surfaceVariant;
    
    return Shimmer.fromColors(
      baseColor: effectBaseColor,
      highlightColor: effectHighlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title placeholder
            Container(
              height: 32,
              width: double.infinity * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            
            // Content placeholders
            _buildContentPlaceholder(),
            const SizedBox(height: 8),
            _buildContentPlaceholder(width: 0.8),
            const SizedBox(height: 8),
            _buildContentPlaceholder(width: 0.9),
            const SizedBox(height: 8),
            _buildContentPlaceholder(width: 0.7),
            const SizedBox(height: 24),
            
            // Action buttons placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContentPlaceholder({double width = 1.0}) {
    return Container(
      height: 16,
      width: double.infinity * width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// A shimmer placeholder for cards
class ShimmerCardPlaceholder extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  
  const ShimmerCardPlaceholder({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.baseColor,
    this.highlightColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectBaseColor = baseColor ?? theme.colorScheme.surface;
    final effectHighlightColor = highlightColor ?? theme.colorScheme.surfaceVariant;
    
    return Shimmer.fromColors(
      baseColor: effectBaseColor,
      highlightColor: effectHighlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
