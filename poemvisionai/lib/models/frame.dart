class Frame {
  final String id;
  final String name;
  final String description;
  final String assetPath;
  final bool isPremium;

  const Frame({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.isPremium,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Frame && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class FrameData {
  static const List<Frame> availableFrames = [
    Frame(
      id: 'classic',
      name: 'Classic',
      description: 'Timeless and elegant frame',
      assetPath: 'assets/frames/classic.jpg',
      isPremium: false,
    ),
    Frame(
      id: 'elegant',
      name: 'Elegant',
      description: 'Sophisticated and refined style',
      assetPath: 'assets/frames/elegant.jpg',
      isPremium: false,
    ),
    Frame(
      id: 'minimalist',
      name: 'Minimalist',
      description: 'Clean and simple design',
      assetPath: 'assets/frames/minimalist.jpg',
      isPremium: false,
    ),
    Frame(
      id: 'modern',
      name: 'Modern',
      description: 'Contemporary and sleek',
      assetPath: 'assets/frames/modern.jpg',
      isPremium: true,
    ),
    Frame(
      id: 'vintage',
      name: 'Vintage',
      description: 'Classic retro style',
      assetPath: 'assets/frames/vintage.jpg',
      isPremium: true,
    ),
  ];

  // Get free frames for non-premium users
  static List<Frame> getFreeFrames() {
    return availableFrames.where((frame) => !frame.isPremium).toList();
  }

  // Get premium frames
  static List<Frame> getPremiumFrames() {
    return availableFrames.where((frame) => frame.isPremium).toList();
  }

  // Get frame by ID
  static Frame? getFrameById(String id) {
    try {
      return availableFrames.firstWhere((frame) => frame.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get available frames based on user's premium status
  static List<Frame> getAvailableFrames(bool isPremium) {
    if (isPremium) {
      return availableFrames;
    } else {
      return getFreeFrames();
    }
  }
}
