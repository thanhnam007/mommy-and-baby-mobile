import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/camera_model.dart';
import '../../../providers/camera_provider.dart';

class CameraStreamPlayer extends StatefulWidget {
  final CameraModel camera;
  final bool isFocused;
  final VoidCallback? onFocus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CameraStreamPlayer({
    super.key,
    required this.camera,
    this.isFocused = false,
    this.onFocus,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CameraStreamPlayer> createState() => _CameraStreamPlayerState();
}

class _CameraStreamPlayerState extends State<CameraStreamPlayer> {
  VideoPlayerController? _controller;
  bool _isPlayingRealtime = false;
  bool _isInitialized = false;
  bool _hasStreamError = false;
  bool _isMuted = true;
  String _quality = 'hd'; // 'hd' or 'sd'
  double _zoomLevel = 1.0;
  bool _isRefreshingSnap = false;

  @override
  void didUpdateWidget(covariant CameraStreamPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera.id != widget.camera.id) {
      _stopRealtimeStream();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRealtimeStream() async {
    final streamUrl = widget.camera.resolvedStreamUrl(quality: _quality);
    if (streamUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera chưa có luồng phát trực tiếp')),
        );
      }
      return;
    }

    setState(() {
      _isPlayingRealtime = true;
      _isInitialized = false;
      _hasStreamError = false;
    });

    try {
      await _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasStreamError = false;
        });
      }
    } catch (e) {
      debugPrint('Video player stream error: $e');
      if (mounted) {
        setState(() {
          _hasStreamError = true;
          _isPlayingRealtime = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối luồng phát: $e')),
        );
      }
    }
  }

  void _stopRealtimeStream() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _isPlayingRealtime = false;
        _isInitialized = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlayingRealtime) {
      _stopRealtimeStream();
    } else {
      _startRealtimeStream();
    }
  }

  void _toggleQuality() {
    setState(() {
      _quality = _quality == 'hd' ? 'sd' : 'hd';
    });
    if (_isPlayingRealtime) {
      _startRealtimeStream();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _cycleZoom() {
    setState(() {
      if (_zoomLevel >= 2.0) {
        _zoomLevel = 1.0;
      } else if (_zoomLevel >= 1.5) {
        _zoomLevel = 2.0;
      } else {
        _zoomLevel = 1.5;
      }
    });
  }

  Future<void> _captureSnapshot() async {
    setState(() => _isRefreshingSnap = true);
    final camProv = Provider.of<CameraProvider>(context, listen: false);
    await camProv.refreshSnapshot(cameraId: widget.camera.id);
    if (mounted) {
      setState(() => _isRefreshingSnap = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chụp và cập nhật khung hình mới! 📸')),
      );
    }
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildVideoOrPreview(),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOrPreview() {
    final snapUrl = widget.camera.resolvedSnapshotUrl;

    if (!widget.camera.isOnline) {
      return Container(
        color: const Color(0xFF111827),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 44),
              const SizedBox(height: 8),
              const Text(
                'Camera Ngoại tuyến (Offline)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'S/N: ${widget.camera.deviceId}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (_isPlayingRealtime && _isInitialized && _controller != null && !_hasStreamError) {
      return ClipRect(
        child: Transform.scale(
          scale: _zoomLevel,
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }

    // Preview Snapshot Frame
    return Stack(
      fit: StackFit.expand,
      children: [
        if (snapUrl != null && snapUrl.isNotEmpty)
          Transform.scale(
            scale: _zoomLevel,
            child: Image.network(
              snapUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackSnapshotView(),
            ),
          )
        else
          _buildFallbackSnapshotView(),

        // Action Overlay
        Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Xem trực tiếp (Real-time)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _startRealtimeStream,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    '🖼️ Chế độ Preview tiết kiệm băng thông',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackSnapshotView() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Colors.white.withValues(alpha: _isRefreshingSnap ? 0.8 : 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              _isRefreshingSnap ? 'Đang cập nhật khung hình...' : 'Khung hình xem trước',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nowTime = DateFormat('HH:mm:ss').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isFocused
              ? AppTheme.brand500
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          width: widget.isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Viewport Frame
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                _buildVideoOrPreview(),

                // Top HUD: Status Badge + Title + Real-time Clock
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Live or Preview Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: !widget.camera.isOnline
                                ? Colors.grey.shade700
                                : (_isPlayingRealtime ? Colors.red.shade600 : Colors.amber.shade700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                !widget.camera.isOnline
                                    ? 'OFFLINE'
                                    : (_isPlayingRealtime ? 'LIVE' : 'PREVIEW'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Camera Name
                        Expanded(
                          child: Text(
                            widget.camera.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Quality Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Text(
                            _quality.toUpperCase(),
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Clock
                        Text(
                          nowTime,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                        ),

                        // Menu Options
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (val) {
                            if (val == 'edit') widget.onEdit?.call();
                            if (val == 'delete') widget.onDelete?.call();
                            if (val == 'refresh') {
                              Provider.of<CameraProvider>(context, listen: false)
                                  .refreshCameraStream(cameraId: widget.camera.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'refresh',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, size: 16),
                                  SizedBox(width: 8),
                                  Text('Làm mới luồng', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Đổi tên camera', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Xóa camera', style: TextStyle(fontSize: 12, color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Video Controls Bar (Only when Live or Hover)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Play / Pause toggle
                        IconButton(
                          icon: Icon(
                            _isPlayingRealtime ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),

                        // Quality Button
                        InkWell(
                          onTap: _toggleQuality,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _quality.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Mute Toggle
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _toggleMute,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Spacer(),

                        // Digital Zoom
                        InkWell(
                          onTap: _cycleZoom,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _zoomLevel > 1.0 ? AppTheme.brand500 : Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_zoomLevel.toStringAsFixed(1)}x',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Snapshot button
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                          onPressed: _captureSnapshot,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Chụp ảnh bé',
                        ),
                        const SizedBox(width: 8),

                        // Fullscreen
                        IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                          onPressed: () => _openFullscreen(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar for Sub-info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.camera.deviceModel ?? 'Imou IPC Series',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        ),
                      ),
                      Text(
                        'Mã S/N: ${widget.camera.deviceId}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isFocused && widget.onFocus != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.center_focus_strong, size: 15),
                    label: const Text('Xem tiêu điểm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: widget.onFocus,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
