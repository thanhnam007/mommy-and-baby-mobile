import '../core/config/app_config.dart';

class CameraModel {
  final int id;
  final int? userId;
  final int? babyId;
  final String deviceId;
  final String channelId;
  final String name;
  final String? deviceModel;
  final String status; // 'online' or 'offline'
  final String? sourceType;
  final String? snapshotUrl;
  final String? hlsHdUrl;
  final String? hlsSdUrl;
  final String? kitToken;
  final bool isPtzSupported;
  final DateTime? lastSyncedAt;

  CameraModel({
    required this.id,
    this.userId,
    this.babyId,
    required this.deviceId,
    this.channelId = '0',
    required this.name,
    this.deviceModel,
    required this.status,
    this.sourceType,
    this.snapshotUrl,
    this.hlsHdUrl,
    this.hlsSdUrl,
    this.kitToken,
    required this.isPtzSupported,
    this.lastSyncedAt,
  });

  bool get isOnline => status.toLowerCase() == 'online';
  bool get hasStream => (hlsHdUrl != null && hlsHdUrl!.isNotEmpty) || (hlsSdUrl != null && hlsSdUrl!.isNotEmpty);

  String? get resolvedSnapshotUrl {
    if (snapshotUrl == null || snapshotUrl!.isEmpty) return null;
    if (snapshotUrl!.startsWith('http')) return snapshotUrl;
    final baseHost = AppConfig.baseUrl.replaceAll('/api', '');
    return '$baseHost$snapshotUrl';
  }

  String? resolvedStreamUrl({String quality = 'hd'}) {
    final raw = (quality == 'sd' && hlsSdUrl != null && hlsSdUrl!.isNotEmpty)
        ? hlsSdUrl!
        : (hlsHdUrl ?? hlsSdUrl);
    if (raw == null || raw.isEmpty) return null;

    // Direct mp4 video file (e.g. demo video)
    if (raw.endsWith('.mp4')) {
      if (raw.startsWith('http')) return raw;
      final baseHost = AppConfig.baseUrl.replaceAll('/api', '');
      return '$baseHost$raw';
    }

    // For Imou live HLS streams, use backend proxy which normalizes TLS/ports and rewrites TS segments
    final baseHost = AppConfig.baseUrl.replaceAll('/api', '');
    return '$baseHost/api/cameras/$id/hls.m3u8?quality=$quality';
  }

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      babyId: json['baby_id'] is int ? json['baby_id'] : int.tryParse(json['baby_id']?.toString() ?? ''),
      deviceId: json['device_id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Camera Imou',
      deviceModel: json['device_model']?.toString(),
      status: json['status']?.toString() ?? 'offline',
      sourceType: json['source_type']?.toString(),
      snapshotUrl: json['snapshot_url']?.toString(),
      hlsHdUrl: json['hls_hd_url']?.toString(),
      hlsSdUrl: json['hls_sd_url']?.toString(),
      kitToken: json['kit_token']?.toString(),
      isPtzSupported: json['is_ptz_supported'] == true,
      lastSyncedAt: json['last_synced_at'] != null ? DateTime.tryParse(json['last_synced_at'].toString()) : null,
    );
  }
}
