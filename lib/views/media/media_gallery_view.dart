import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/baby_provider.dart';
import '../../providers/media_provider.dart';
import 'fullscreen_media_viewer.dart';

class MediaGalleryView extends StatefulWidget {
  const MediaGalleryView({super.key});

  @override
  State<MediaGalleryView> createState() => _MediaGalleryViewState();
}

class _MediaGalleryViewState extends State<MediaGalleryView> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
      if (baby != null) {
        Provider.of<MediaProvider>(context, listen: false).fetchMedia(baby.id);
      }
    });
  }

  void _pickAndUploadImage(BuildContext context, ImageSource source) async {
    final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
    if (baby == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (!context.mounted) return;
    final mediaProv = Provider.of<MediaProvider>(context, listen: false);
    final ok = await mediaProv.uploadMedia(File(picked.path), baby.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Đã tải ảnh kỷ niệm lên thành công! 📸' : 'Tải ảnh thất bại'),
          backgroundColor: ok ? AppTheme.emerald500 : Colors.redAccent,
        ),
      );
    }
  }

  void _pickAndUploadVideo(BuildContext context, ImageSource source) async {
    final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
    if (baby == null) return;

    final picked = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5));
    if (picked == null) return;

    if (!context.mounted) return;
    final mediaProv = Provider.of<MediaProvider>(context, listen: false);
    final ok = await mediaProv.uploadMedia(File(picked.path), baby.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Đã tải video kỷ niệm lên thành công! 🎥' : 'Tải video thất bại'),
          backgroundColor: ok ? AppTheme.emerald500 : Colors.redAccent,
        ),
      );
    }
  }

  void _pickMediaFromGallery(BuildContext context) async {
    final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
    if (baby == null) return;

    final picked = await _picker.pickMedia();
    if (picked == null) return;

    if (!context.mounted) return;
    final mediaProv = Provider.of<MediaProvider>(context, listen: false);
    final ok = await mediaProv.uploadMedia(File(picked.path), baby.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Đã tải file kỷ niệm lên thành công! 🎉' : 'Tải file thất bại'),
          backgroundColor: ok ? AppTheme.emerald500 : Colors.redAccent,
        ),
      );
    }
  }

  void _openViewer(BuildContext context, int initialIndex, int babyId) {
    final mediaProv = Provider.of<MediaProvider>(context, listen: false);
    FullscreenMediaViewer.show(
      context,
      items: mediaProv.mediaList,
      initialIndex: initialIndex,
      babyId: babyId,
      onDelete: (item) async {
        await mediaProv.deleteMedia(item.id, babyId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyProvider>(context).activeBaby;
    final mediaProv = Provider.of<MediaProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (baby == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng chọn bé')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho ảnh & Video kỷ niệm (VIP)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mediaProv.fetchMedia(baby.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Thêm ảnh / Video'),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.perm_media_outlined, color: AppTheme.brand500),
                      title: const Text('Chọn ảnh hoặc video từ Thư viện'),
                      subtitle: const Text('Chọn từ bộ sưu tập trên máy', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickMediaFromGallery(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam_outlined, color: Colors.indigoAccent),
                      title: const Text('Quay video mới'),
                      subtitle: const Text('Mở camera để quay clip bé', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUploadVideo(context, ImageSource.camera);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.emerald500),
                      title: const Text('Chụp ảnh mới'),
                      subtitle: const Text('Mở camera để chụp ảnh bé', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUploadImage(context, ImageSource.camera);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      body: mediaProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mediaProv.mediaList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📸', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('Chưa có hình ảnh hoặc video kỷ niệm nào', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'Hãy bấm nút "Thêm ảnh / Video" ở dưới để lưu giữ khoảnh khắc đáng nhớ!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: mediaProv.mediaList.length,
                  itemBuilder: (context, index) {
                    final item = mediaProv.mediaList[index];
                    String fullUrl = item.fileUrl;
                    if (!fullUrl.startsWith('http')) {
                      final baseHost = AppConfig.baseUrl.replaceAll('/api', '');
                      fullUrl = '$baseHost$fullUrl';
                    }

                    return InkWell(
                      onTap: () => _openViewer(context, index, baby.id),
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.isVideo
                            ? Container(
                                color: Colors.grey.shade900,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill_rounded,
                                        size: 42,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.videocam, size: 10, color: Colors.white),
                                            SizedBox(width: 3),
                                            Text(
                                              'VIDEO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                                errorWidget: (_, __, ___) => Container(
                                  color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                                  child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                                ),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
