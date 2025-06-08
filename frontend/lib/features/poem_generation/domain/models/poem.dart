/// Model representing a generated poem
class Poem {
  final String id;
  final String content;
  final String title;
  final String poemType;
  final String analysisId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final bool isEdited;
  final String? originalContent;

  const Poem({
    required this.id,
    required this.content,
    required this.title,
    required this.poemType,
    required this.analysisId,
    required this.createdAt,
    this.metadata,
    this.tags,
    this.isEdited = false,
    this.originalContent,
  });

  /// Factory constructor to create a Poem from JSON
  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      id: json['id'] as String,
      content: json['content'] as String,
      title: json['title'] as String,
      poemType: json['poem_type'] as String,
      analysisId: json['analysis_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isEdited: json['is_edited'] as bool? ?? false,
      originalContent: json['original_content'] as String?,
    );
  }

  /// Convert Poem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'title': title,
      'poem_type': poemType,
      'analysis_id': analysisId,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'tags': tags,
      'is_edited': isEdited,
      'original_content': originalContent,
    };
  }

  /// Get a copy of this Poem with updated fields
  Poem copyWith({
    String? id,
    String? content,
    String? title,
    String? poemType,
    String? analysisId,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isEdited,
    String? originalContent,
  }) {
    return Poem(
      id: id ?? this.id,
      content: content ?? this.content,
      title: title ?? this.title,
      poemType: poemType ?? this.poemType,
      analysisId: analysisId ?? this.analysisId,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isEdited: isEdited ?? this.isEdited,
      originalContent: originalContent ?? this.originalContent,
    );
  }

  /// Edit the poem content
  Poem edit({
    required String newContent,
    String? newTitle,
  }) {
    // If this is the first edit, save the original content
    final originalToSave = isEdited ? originalContent : content;
    
    return copyWith(
      content: newContent,
      title: newTitle ?? title,
      isEdited: true,
      originalContent: originalToSave,
    );
  }

  /// Get the number of lines in the poem
  int get lineCount {
    return content.split('\n').where((line) => line.trim().isNotEmpty).length;
  }

  /// Get the word count of the poem
  int get wordCount {
    return content
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
  }

  /// Check if the poem has been modified
  bool get isModified {
    return isEdited;
  }

  /// Revert to the original poem (if edited)
  Poem? revertToOriginal() {
    if (!isEdited || originalContent == null) {
      return null;
    }
    
    return copyWith(
      content: originalContent!,
      isEdited: false,
      originalContent: null,
    );
  }
}
