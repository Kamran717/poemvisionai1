class PersonalizationData {
  final String? personName;
  final String? relationship;
  final String? occasion;
  final String? location;
  final String? emotion;
  final String? customMessage;

  PersonalizationData({
    this.personName,
    this.relationship,
    this.occasion,
    this.location,
    this.emotion,
    this.customMessage,
  });

  bool get isEmpty {
    return (personName?.trim().isEmpty ?? true) &&
           (relationship?.trim().isEmpty ?? true) &&
           (occasion?.trim().isEmpty ?? true) &&
           (location?.trim().isEmpty ?? true) &&
           (emotion?.trim().isEmpty ?? true) &&
           (customMessage?.trim().isEmpty ?? true);
  }

  bool get hasPersonalDetails {
    return personName?.trim().isNotEmpty == true || 
           relationship?.trim().isNotEmpty == true;
  }

  Map<String, dynamic> toStructuredPrompt() {
    if (isEmpty) return {};

    final Map<String, String> promptData = {};
    
    if (personName?.trim().isNotEmpty == true) {
      promptData['name'] = personName!.trim();
    }
    
    if (location?.trim().isNotEmpty == true) {
      promptData['place'] = location!.trim();
    }
    
    if (emotion?.trim().isNotEmpty == true) {
      promptData['emotion'] = emotion!.trim();
    }
    
    if (occasion?.trim().isNotEmpty == true) {
      promptData['action'] = occasion!.trim();
    }
    
    // Combine additional details
    final List<String> additionalParts = [];
    if (relationship?.trim().isNotEmpty == true) {
      additionalParts.add('Relationship: ${relationship!.trim()}');
    }
    if (customMessage?.trim().isNotEmpty == true) {
      additionalParts.add(customMessage!.trim());
    }
    
    if (additionalParts.isNotEmpty) {
      promptData['additional'] = additionalParts.join('; ');
    }

    return {
      'category': 'structured',
      ...promptData,
    };
  }

  @override
  String toString() {
    return 'PersonalizationData(personName: $personName, relationship: $relationship, '
           'occasion: $occasion, location: $location, emotion: $emotion, '
           'customMessage: $customMessage)';
  }
}

class PersonalizationOptions {
  static const List<String> relationships = [
    'Friend',
    'Best Friend',
    'Family Member',
    'Mother',
    'Father',
    'Sister',
    'Brother',
    'Partner',
    'Spouse',
    'Child',
    'Colleague',
    'Teacher',
    'Mentor',
    'Pet',
    'Myself',
  ];

  static const List<String> emotions = [
    'Happy',
    'Joyful',
    'Romantic',
    'Nostalgic',
    'Grateful',
    'Proud',
    'Peaceful',
    'Excited',
    'Hopeful',
    'Loving',
    'Reflective',
    'Celebratory',
  ];

  static const List<String> occasions = [
    'Birthday',
    'Anniversary',
    'Wedding',
    'Graduation',
    'Retirement',
    'New Job',
    'Moving Away',
    'Holiday',
    'Valentine\'s Day',
    'Mother\'s Day',
    'Father\'s Day',
    'Christmas',
    'New Year',
    'Memorial',
  ];
}
