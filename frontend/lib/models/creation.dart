class Creation {
  final int id;
  final int? userId;
  final String imageData;
  final Map<String, dynamic>? analysisResults;
  final String? poemText;
  final String? frameStyle;
  final String? finalImageData;
  final String? poemType;
  final Map<String, dynamic>? emphasis;
  final String? poemLength;
  final int? timeSavedMinutes;
  final DateTime createdAt;
  final String? shareCode;
  final bool isDownloaded;
  final int downloadCount;
  final int viewCount;
  final DateTime? lastViewedAt;
  final DateTime? lastDownloadedAt;

  Creation({
    required this.id,
    this.userId,
    required this.imageData,
    this.analysisResults,
    this.poemText,
    this.frameStyle,
    this.finalImageData,
    this.poemType,
    this.emphasis,
    this.poemLength,
    this.timeSavedMinutes,
    required this.createdAt,
    this.shareCode,
    this.isDownloaded = false,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.lastViewedAt,
    this.lastDownloadedAt,
  });

  factory Creation.fromJson(Map<String, dynamic> json) {
    return Creation(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      imageData: json['image_data'] ?? json['imageData'] ?? '',
      analysisResults: _parseAsMap(json['analysis_results'] ?? json['analysisResults']),
      poemText: json['poem_text'] ?? json['poemText'],
      frameStyle: json['frame_style'] ?? json['frameStyle'],
      finalImageData: json['final_image_data'] ?? json['finalImageData'],
      poemType: json['poem_type'] ?? json['poemType'],
      emphasis: _parseAsMap(json['emphasis']),
      poemLength: json['poem_length'] ?? json['poemLength'],
      timeSavedMinutes: json['time_saved_minutes'] ?? json['timeSavedMinutes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['createdAt'] != null 
              ? DateTime.parse(json['createdAt']) 
              : DateTime.now()),
      shareCode: json['share_code'] ?? json['shareCode'],
      isDownloaded: json['is_downloaded'] ?? json['isDownloaded'] ?? false,
      downloadCount: json['download_count'] ?? json['downloadCount'] ?? 0,
      viewCount: json['view_count'] ?? json['viewCount'] ?? 0,
      lastViewedAt: json['last_viewed_at'] != null 
          ? DateTime.parse(json['last_viewed_at']) 
          : (json['lastViewedAt'] != null 
              ? DateTime.parse(json['lastViewedAt']) 
              : null),
      lastDownloadedAt: json['last_downloaded_at'] != null 
          ? DateTime.parse(json['last_downloaded_at']) 
          : (json['lastDownloadedAt'] != null 
              ? DateTime.parse(json['lastDownloadedAt']) 
              : null),
    );
  }

  // Helper method to safely parse dynamic data as Map<String, dynamic>
  static Map<String, dynamic>? _parseAsMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is List) {
      // If it's a list, convert to a map with index as keys
      return Map<String, dynamic>.fromIterable(
        value.asMap().entries,
        key: (entry) => entry.key.toString(),
        value: (entry) => entry.value,
      );
    }
    // If it's a primitive type, wrap it in a map
    return {'value': value};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_data': imageData,
      'analysis_results': analysisResults,
      'poem_text': poemText,
      'frame_style': frameStyle,
      'final_image_data': finalImageData,
      'poem_type': poemType,
      'emphasis': emphasis,
      'poem_length': poemLength,
      'time_saved_minutes': timeSavedMinutes,
      'created_at': createdAt.toIso8601String(),
      'share_code': shareCode,
      'is_downloaded': isDownloaded,
      'download_count': downloadCount,
      'view_count': viewCount,
      'last_viewed_at': lastViewedAt?.toIso8601String(),
      'last_downloaded_at': lastDownloadedAt?.toIso8601String(),
    };
  }
}
