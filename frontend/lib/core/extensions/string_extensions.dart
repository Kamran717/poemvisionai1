/// Extensions for String class
extension StringExtensions on String {
  /// Capitalize the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  /// Capitalize the first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  /// Convert to title case
  String toTitleCase() {
    if (isEmpty) return this;
    
    final List<String> nonCapitalizedWords = [
      'a', 'an', 'the', 'and', 'but', 'or', 'for', 'nor', 'on', 'at', 
      'to', 'from', 'by', 'in', 'of', 'with', 'as'
    ];
    
    List<String> words = split(' ');
    for (int i = 0; i < words.length; i++) {
      if (i == 0 || !nonCapitalizedWords.contains(words[i].toLowerCase())) {
        words[i] = words[i].capitalize();
      } else {
        words[i] = words[i].toLowerCase();
      }
    }
    
    return words.join(' ');
  }
  
  /// Truncate string to a specified length with an optional suffix
  String truncate(int maxLength, {String suffix = '...'}) {
    if (isEmpty || length <= maxLength) return this;
    return substring(0, maxLength - suffix.length) + suffix;
  }
  
  /// Convert to camel case
  String toCamelCase() {
    if (isEmpty) return this;
    
    List<String> words = split(RegExp(r'[^a-zA-Z0-9]'));
    words = words.where((word) => word.isNotEmpty).toList();
    
    if (words.isEmpty) return '';
    
    String result = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      result += words[i].capitalize();
    }
    
    return result;
  }
  
  /// Convert to snake case
  String toSnakeCase() {
    if (isEmpty) return this;
    
    String result = replaceAllMapped(
      RegExp(r'[A-Z]'), 
      (Match match) => '_${match.group(0)!.toLowerCase()}'
    );
    
    // Replace non-alphanumeric chars with underscore
    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    
    // Remove leading underscore if present
    if (result.startsWith('_')) {
      result = result.substring(1);
    }
    
    // Remove consecutive underscores
    result = result.replaceAll(RegExp(r'_+'), '_');
    
    return result.toLowerCase();
  }
  
  /// Check if the string is a valid email
  bool get isValidEmail {
    if (isEmpty) return false;
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    return emailRegExp.hasMatch(this);
  }
  
  /// Check if the string is a valid URL
  bool get isValidUrl {
    if (isEmpty) return false;
    
    final urlRegExp = RegExp(
      r'^(http|https)://[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
    );
    
    return urlRegExp.hasMatch(this);
  }
  
  /// Check if the string contains only digits
  bool get isNumeric {
    if (isEmpty) return false;
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }
  
  /// Convert string to DateTime object
  DateTime? toDateTime() {
    try {
      return DateTime.parse(this);
    } catch (e) {
      return null;
    }
  }
  
  /// Get the file extension from a path string
  String get fileExtension {
    return contains('.')
        ? substring(lastIndexOf('.') + 1).toLowerCase()
        : '';
  }
  
  /// Check if the string is a valid hex color
  bool get isValidHexColor {
    if (isEmpty) return false;
    
    final hexColorRegExp = RegExp(
      r'^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$',
    );
    
    return hexColorRegExp.hasMatch(this);
  }
}
