import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyUrl(String url) async {
    await AppConfig.setBaseUrl(url);
    ApiClient().updateBaseUrl();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật máy chủ: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: Color(0xFFDF4D67)),
          SizedBox(width: 8),
          Text('Cài đặt Máy chủ API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn hoặc nhập địa chỉ API máy chủ kết nối:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://127.0.0.1:8000/api',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gợi ý cài đặt nhanh:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('USB / ADB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  onPressed: () => _controller.text = AppConfig.defaultBaseUrl,
                ),
                ActionChip(
                  label: const Text('Wi-Fi LAN (192.168.1.132)', style: TextStyle(fontSize: 11)),
                  onPressed: () => _controller.text = AppConfig.lanBaseUrl,
                ),
                ActionChip(
                  label: const Text('Máy ảo (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => _controller.text = AppConfig.emulatorBaseUrl,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => _applyUrl(_controller.text),
          child: const Text('Lưu & Áp dụng'),
        ),
      ],
    );
  }
}
