class MediaModel {
  final int id;
  final int babyId;
  final int? activityId;
  final String fileType; // 'image' or 'video'
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String? caption;
  final String createdAt;

  MediaModel({
    required this.id,
    required this.babyId,
    this.activityId,
    required this.fileType,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.caption,
    required this.createdAt,
  });

  bool get isVideo => fileType == 'video';

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      babyId: json['baby_id'] is int ? json['baby_id'] : int.tryParse(json['baby_id'].toString()) ?? 0,
      activityId: json['activity_id'],
      fileType: json['file_type'] ?? 'image',
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] ?? 0,
      caption: json['caption'],
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
