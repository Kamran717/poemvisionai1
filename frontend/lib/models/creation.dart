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
      id: json['id'],
      userId: json['user_id'],
      imageData: json['image_data'],
      analysisResults: json['analysis_results'],
      poemText: json['poem_text'],
      frameStyle: json['frame_style'],
      finalImageData: json['final_image_data'],
      poemType: json['poem_type'],
      emphasis: json['emphasis'],
      poemLength: json['poem_length'],
      timeSavedMinutes: json['time_saved_minutes'],
      createdAt: DateTime.parse(json['created_at']),
      shareCode: json['share_code'],
      isDownloaded: json['is_downloaded'] ?? false,
      downloadCount: json['download_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      lastViewedAt: json['last_viewed_at'] != null 
          ? DateTime.parse(json['last_viewed_at']) 
          : null,
      lastDownloadedAt: json['last_downloaded_at'] != null 
          ? DateTime.parse(json['last_downloaded_at']) 
          : null,
    );
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
