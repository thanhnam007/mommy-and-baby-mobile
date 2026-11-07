import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/camera_model.dart';
import '../../../providers/camera_provider.dart';

class ImouSettingsSheet extends StatefulWidget {
  final CameraModel? cameraToEdit;

  const ImouSettingsSheet({super.key, this.cameraToEdit});

  @override
  State<ImouSettingsSheet> createState() => _ImouSettingsSheetState();
}

class _ImouSettingsSheetState extends State<ImouSettingsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Imou Account Form
  late TextEditingController _appIdController;
  late TextEditingController _appSecretController;
  late TextEditingController _apiBaseUrlController;
  bool _obscureSecret = true;
  bool _isSavingImou = false;

  // Manual Camera Form
  late TextEditingController _manualNameController;
  late TextEditingController _manualDeviceIdController;
  late TextEditingController _manualChannelController;
  late TextEditingController _manualStreamUrlController;
  late TextEditingController _manualSnapshotUrlController;
  bool _isSavingManual = false;

  // Edit Camera Form
  late TextEditingController _editNameController;
  bool _isSavingEdit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.cameraToEdit != null ? 1 : 3, vsync: this);

    final camProv = Provider.of<CameraProvider>(context, listen: false);
    _appIdController = TextEditingController(text: camProv.appId ?? camProv.appIdMasked ?? '');
    _appSecretController = TextEditingController(text: camProv.appSecretMasked ?? '');
    _apiBaseUrlController = TextEditingController(text: camProv.apiBaseUrl);

    _manualNameController = TextEditingController(text: 'Camera Phòng Bé');
    _manualDeviceIdController = TextEditingController();
    _manualChannelController = TextEditingController(text: '0');
    _manualStreamUrlController = TextEditingController();
    _manualSnapshotUrlController = TextEditingController();

    _editNameController = TextEditingController(text: widget.cameraToEdit?.name ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appIdController.dispose();
    _appSecretController.dispose();
    _apiBaseUrlController.dispose();
    _manualNameController.dispose();
    _manualDeviceIdController.dispose();
    _manualChannelController.dispose();
    _manualStreamUrlController.dispose();
    _manualSnapshotUrlController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  Future<void> _submitConnectImou() async {
    final appId = _appIdController.text.trim();
    final appSecret = _appSecretController.text.trim();
    if (appId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Imou App ID')),
      );
      return;
    }

    setState(() => _isSavingImou = true);
    final camProv = Provider.of<CameraProvider>(context, listen: false);
    final ok = await camProv.connectImou(
      appId: appId,
      appSecret: appSecret.isNotEmpty ? appSecret : null,
      apiBaseUrl: _apiBaseUrlController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSavingImou = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kết nối và đồng bộ Camera Imou thành công! 🎉')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kết nối Imou thất bại. Vui lòng kiểm tra lại App ID / App Secret')),
        );
      }
    }
  }

  Future<void> _submitDisconnectImou() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy kết nối Imou?'),
        content: const Text('Hệ thống sẽ ngắt kết nối tài khoản Imou này và xóa danh sách camera tương ứng khỏi thiết bị.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy liên kết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final camProv = Provider.of<CameraProvider>(context, listen: false);
      await camProv.disconnectImou();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy liên kết Imou')),
        );
      }
    }
  }

  Future<void> _submitManualCamera() async {
    final name = _manualNameController.text.trim();
    final devId = _manualDeviceIdController.text.trim();
    final streamUrl = _manualStreamUrlController.text.trim();

    if (name.isEmpty || devId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Tên Camera và Mã thiết bị (S/N)')),
      );
      return;
    }

    setState(() => _isSavingManual = true);
    final camProv = Provider.of<CameraProvider>(context, listen: false);
    final ok = await camProv.createManualCamera({
      'name': name,
      'device_id': devId,
      'channel_id': _manualChannelController.text.trim(),
      'hls_hd_url': streamUrl.isNotEmpty ? streamUrl : null,
      'hls_sd_url': streamUrl.isNotEmpty ? streamUrl : null,
      'snapshot_url': _manualSnapshotUrlController.text.trim().isNotEmpty
          ? _manualSnapshotUrlController.text.trim()
          : null,
    });

    if (mounted) {
      setState(() => _isSavingManual = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm camera thủ công thành công! 📹')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thêm camera. Vui lòng kiểm tra lại thông tin')),
        );
      }
    }
  }

  Future<void> _submitSeedDemo() async {
    final camProv = Provider.of<CameraProvider>(context, listen: false);
    final ok = await camProv.seedDemoCameras();
    if (mounted) {
      Navigator.pop(context);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã khởi tạo 2 Camera Mẫu thành công! ✨')),
        );
      }
    }
  }

  Future<void> _submitEditCamera() async {
    if (widget.cameraToEdit == null) return;
    final newName = _editNameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSavingEdit = true);
    final camProv = Provider.of<CameraProvider>(context, listen: false);
    final ok = await camProv.updateCamera(widget.cameraToEdit!.id, {'name': newName});

    if (mounted) {
      setState(() => _isSavingEdit = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tên camera!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final camProv = Provider.of<CameraProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.cameraToEdit != null ? '✏️ Chỉnh sửa Camera' : '⚙️ Cài đặt Imou BabyCam',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          if (widget.cameraToEdit == null) ...[
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.brand500,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              indicatorColor: AppTheme.brand500,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Imou Cloud'),
                Tab(text: 'Thủ công'),
                Tab(text: 'Camera Mẫu'),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Tab views
          SizedBox(
            height: widget.cameraToEdit != null ? 140 : 340,
            child: widget.cameraToEdit != null
                ? _buildEditCameraView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildImouCloudTab(camProv, isDark),
                      _buildManualTab(isDark),
                      _buildDemoSeedTab(isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCameraView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _editNameController,
          decoration: const InputDecoration(
            labelText: 'Tên hiển thị của Camera',
            prefixIcon: Icon(Icons.videocam_outlined),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brand500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSavingEdit ? null : _submitEditCamera,
          child: Text(_isSavingEdit ? 'Đang lưu...' : 'Lưu thay đổi'),
        ),
      ],
    );
  }

  Widget _buildImouCloudTab(CameraProvider camProv, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.brand500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.brand500.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '💡 Nhập App ID & App Secret từ open.imoulife.com. Hệ thống sẽ tự động quét và kết nối tất cả Camera của bạn.',
              style: TextStyle(fontSize: 11, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _appIdController,
            decoration: const InputDecoration(
              labelText: 'Imou App ID',
              prefixIcon: Icon(Icons.key, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _appSecretController,
            obscureText: _obscureSecret,
            decoration: InputDecoration(
              labelText: 'Imou App Secret',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_obscureSecret ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _apiBaseUrlController,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              prefixIcon: Icon(Icons.link, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSavingImou
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync, size: 18),
            label: Text(_isSavingImou ? 'Đang kết nối...' : 'Lưu & Quét Camera Imou'),
            onPressed: _isSavingImou ? null : _submitConnectImou,
          ),

          if (camProv.imouConnected) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text('Hủy liên kết tài khoản Imou'),
              onPressed: _submitDisconnectImou,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _manualNameController,
            decoration: const InputDecoration(labelText: 'Tên camera (VD: Phòng ngủ bé)', isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _manualDeviceIdController,
            decoration: const InputDecoration(labelText: 'Mã thiết bị / S/N (Bắt buộc)', isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _manualChannelController,
            decoration: const InputDecoration(labelText: 'Channel ID (Mặc định: 0)', isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _manualStreamUrlController,
            decoration: const InputDecoration(labelText: 'Đường dẫn luồng HLS (.m3u8)', isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _manualSnapshotUrlController,
            decoration: const InputDecoration(labelText: 'Đường dẫn ảnh Snapshot', isDense: true),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSavingManual ? null : _submitManualCamera,
            child: Text(_isSavingManual ? 'Đang thêm...' : 'Thêm Camera'),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSeedTab(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.video_library_outlined, size: 48, color: AppTheme.brand500),
        const SizedBox(height: 12),
        const Text(
          'Trải nghiệm ngay với 2 Camera Mẫu',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Khởi tạo nhanh Camera Nôi Em Bé (Imou Ranger 2) và Camera Góc Chơi (Imou Rex 3D) để kiểm tra các tính năng Live Stream và PTZ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emerald500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('✨ Tạo 2 Camera Mẫu (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _submitSeedDemo,
        ),
      ],
    );
  }
}
