import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/camera_model.dart';
import '../../providers/baby_provider.dart';
import '../../providers/camera_provider.dart';
import 'widgets/camera_ptz_pad.dart';
import 'widgets/camera_stream_player.dart';
import 'widgets/imou_settings_sheet.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
      Provider.of<CameraProvider>(context, listen: false).fetchCameras(babyId: baby?.id);
    });
  }

  void _sendPTZ(String dir) async {
    final camProv = Provider.of<CameraProvider>(context, listen: false);
    final ok = await camProv.controlPTZ(dir);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi lệnh xoay: $dir')),
      );
    }
  }

  void _openSettingsModal({CameraModel? cameraToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImouSettingsSheet(cameraToEdit: cameraToEdit),
    );
  }

  Future<void> _handleDeleteCamera(CameraModel cam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa Camera'),
        content: Text('Bạn có chắc chắn muốn xóa camera "${cam.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<CameraProvider>(context, listen: false).deleteCamera(cam.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Đã xóa camera' : 'Không thể xóa camera')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camProv = Provider.of<CameraProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cameras = camProv.cameras;
    final focusedCam = camProv.selectedCamera ?? (cameras.isNotEmpty ? cameras.first : null);

    return RefreshIndicator(
      color: AppTheme.brand500,
      onRefresh: () => camProv.fetchCameras(silent: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header & Status Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text('📹', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'BabyCam Live',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.brand500,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fiber_manual_record, size: 7, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Settings button
                      InkWell(
                        onTap: () => _openSettingsModal(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.brand500, AppTheme.brand400],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brand500.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                camProv.imouConnected ? Icons.settings : Icons.add_link,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                camProv.imouConnected ? 'Cài đặt' : 'Kết nối',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status chips & view mode switcher
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Imou Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: camProv.imouConnected
                                  ? (isDark ? AppTheme.emerald500.withValues(alpha: 0.2) : const Color(0xFFECFDF5))
                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              camProv.imouConnected
                                  ? '🟢 Imou (${camProv.appIdMasked ?? "Online"})'
                                  : '⚪ Chưa gắn AppID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: camProv.imouConnected
                                    ? AppTheme.emerald500
                                    : (isDark ? Colors.white60 : Colors.grey.shade700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Camera Count Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.brand500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '📷 ${cameras.length} Cam',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brand500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Sync button
                          if (camProv.imouConnected)
                            InkWell(
                              onTap: camProv.isSyncing ? null : () => camProv.syncImou(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    camProv.isSyncing
                                        ? const SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(strokeWidth: 1.5),
                                          )
                                        : const Icon(Icons.sync, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      camProv.isSyncing ? 'Đồng bộ...' : 'Quét Cam',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Mode Switcher (if > 1 camera)
                      if (cameras.length > 1)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => camProv.setViewMode('focus'),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: camProv.viewMode == 'focus'
                                        ? (isDark ? const Color(0xFF334155) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: camProv.viewMode == 'focus'
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: const Text('🖥️ Tiêu điểm', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              InkWell(
                                onTap: () => camProv.setViewMode('grid'),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: camProv.viewMode == 'grid'
                                        ? (isDark ? const Color(0xFF334155) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: camProv.viewMode == 'grid'
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Text('🔲 Tất cả (${cameras.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Content Body
            if (camProv.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.brand500),
                      SizedBox(height: 12),
                      Text('Đang nạp danh sách Camera...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else if (cameras.isEmpty)
              _buildEmptyStateCard(isDark, camProv)
            else if (camProv.viewMode == 'focus' && focusedCam != null)
              _buildFocusModeView(cameras, focusedCam)
            else
              _buildGridModeView(cameras),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark, CameraProvider camProv) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.brand500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('📹', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kết nối tài khoản Imou Camera của bạn',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Điền App ID và App Secret từ tài khoản Imou của bạn (trên open.imoulife.com) để hệ thống tự động hiển thị toàn bộ Camera bạn sở hữu.',
            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Action Buttons
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            icon: const Icon(Icons.key, size: 18),
            label: const Text('🔑 Nhập App ID & App Secret ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => _openSettingsModal(),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emerald500,
              side: const BorderSide(color: AppTheme.emerald500),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('✨ Xem thử 2 Camera Mẫu (Demo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () async {
              final ok = await camProv.seedDemoCameras();
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã tạo 2 camera mẫu thành công! ✨')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeView(List<CameraModel> cameras, CameraModel focusedCam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera Selector Chip Strip
        if (cameras.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cameras.map((c) {
                final isSelected = c.id == focusedCam.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    selectedColor: AppTheme.brand500.withValues(alpha: 0.15),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: isSelected ? AppTheme.brand500 : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    onSelected: (_) {
                      Provider.of<CameraProvider>(context, listen: false).selectCamera(c);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Main Player
        CameraStreamPlayer(
          key: ValueKey('cam_${focusedCam.id}'),
          camera: focusedCam,
          isFocused: true,
          onEdit: () => _openSettingsModal(cameraToEdit: focusedCam),
          onDelete: () => _handleDeleteCamera(focusedCam),
        ),
        const SizedBox(height: 16),

        // PTZ Controller (if supported)
        if (focusedCam.isPtzSupported) ...[
          CameraPtzPad(
            cameraName: focusedCam.name,
            onDirection: _sendPTZ,
          ),
          const SizedBox(height: 60),
        ],
      ],
    );
  }

  Widget _buildGridModeView(List<CameraModel> cameras) {
    return Column(
      children: cameras.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CameraStreamPlayer(
            key: ValueKey('grid_cam_${c.id}'),
            camera: c,
            isFocused: false,
            onFocus: () {
              final camProv = Provider.of<CameraProvider>(context, listen: false);
              camProv.selectCamera(c);
              camProv.setViewMode('focus');
            },
            onEdit: () => _openSettingsModal(cameraToEdit: c),
            onDelete: () => _handleDeleteCamera(c),
          ),
        );
      }).toList(),
    );
  }
}
