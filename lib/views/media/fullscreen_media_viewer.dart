import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/media_model.dart';

class FullscreenMediaViewer extends StatefulWidget {
  final List<MediaModel> items;
  final int initialIndex;
  final int babyId;
  final Future<void> Function(MediaModel item)? onDelete;

  const FullscreenMediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.babyId,
    this.onDelete,
  });

  static void show(
    BuildContext context, {
    required List<MediaModel> items,
    required int initialIndex,
    required int babyId,
    Future<void> Function(MediaModel item)? onDelete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      useSafeArea: false,
      builder: (_) => FullscreenMediaViewer(
        items: items,
        initialIndex: initialIndex,
        babyId: babyId,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<MediaModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _currentIndex = widget.initialIndex.clamp(0, _items.isEmpty ? 0 : _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _resolveFullUrl(String url) {
    if (url.startsWith('http')) return url;
    final baseHost = AppConfig.baseUrl.replaceAll('/api', '');
    return '$baseHost$url';
  }

  Future<void> _handleDeleteCurrent() async {
    if (_items.isEmpty) return;
    final current = _items[_currentIndex];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(current.isVideo ? 'Bạn có chắc chắn muốn xóa video này?' : 'Bạn có chắc chắn muốn xóa ảnh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (widget.onDelete != null) {
      await widget.onDelete!(current);
    }

    if (!mounted) return;

    setState(() {
      _items.removeAt(_currentIndex);
      if (_items.isEmpty) {
        Navigator.pop(context);
        return;
      }
      if (_currentIndex >= _items.length) {
        _currentIndex = _items.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = _items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Swipable Media View
            PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (ctx, idx) {
                final item = _items[idx];
                final fullUrl = _resolveFullUrl(item.fileUrl);

                if (item.isVideo) {
                  return VideoPlayerItem(url: fullUrl, key: ValueKey('video_${item.id}_$idx'));
                } else {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: CachedNetworkImage(
                        imageUrl: fullUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),

            // Top Overlay Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 26),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${_items.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                      tooltip: 'Xóa file này',
                      onPressed: _handleDeleteCurrent,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Caption Bar (if notes/caption exist)
            if (current.caption != null && current.caption!.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    current.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String url;

  const VideoPlayerItem({super.key, required this.url});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Không thể phát video này',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.url,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),

            // Tap detector to Play/Pause
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              behavior: HitTestBehavior.translucent,
              child: AnimatedOpacity(
                opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Bottom Progress Bar & Time
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (ctx, val, _) {
                    return Row(
                      children: [
                        Text(
                          _formatDuration(val.position),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppTheme.brand500,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(val.duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
