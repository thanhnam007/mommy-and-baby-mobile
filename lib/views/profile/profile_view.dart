import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/baby_provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _fullNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Imou Camera settings
  final _imouAppIdCtrl = TextEditingController();
  final _imouSecretCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameCtrl.text = user.fullName ?? '';
      _nicknameCtrl.text = user.nickname ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _imouAppIdCtrl.dispose();
    _imouSecretCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    final data = {
      'full_name': _fullNameCtrl.text.trim(),
      'nickname': _nicknameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      if (_passwordCtrl.text.isNotEmpty) 'password': _passwordCtrl.text,
    };

    try {
      final res = await ApiClient().updateProfile(data);
      if (res.statusCode == 200) {
        if (mounted) {
          await Provider.of<AuthProvider>(context, listen: false).checkAuth();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật hồ sơ mẹ thành công! 🎉')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật không thành công')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _connectImou() async {
    final appId = _imouAppIdCtrl.text.trim();
    final appSecret = _imouSecretCtrl.text.trim();
    if (appId.isEmpty) return;

    try {
      final res = await ApiClient().connectImou({
        'app_id': appId,
        if (appSecret.isNotEmpty) 'app_secret': appSecret,
      });
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kết nối tài khoản Imou thành công!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kết nối Imou thất bại. Kiểm tra lại App ID/Secret')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final babyProv = Provider.of<BabyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Mẹ & Bé yêu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mother Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.brand500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Text('👩', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.fullName ?? auth.user?.username ?? 'Mẹ yêu',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '@${auth.user?.username} • ${auth.user?.tier.toUpperCase()}',
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên mẹ', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nicknameCtrl,
                    decoration: const InputDecoration(labelText: 'Biệt danh mẹ', prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Địa chỉ Email', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Đổi mật khẩu mới (bỏ trống nếu không đổi)', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text('Lưu thông tin mẹ'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Baby Profiles Management
            Text(
              'Danh sách Bé yêu (${babyProv.babies.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...babyProv.babies.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                ),
                child: Row(
                  children: [
                    Text(b.genderEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${b.name} ${b.nickname != null ? "(${b.nickname})" : ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('🎂 ${b.ageText} • Ngày sinh: ${b.birthDate}', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // 3. Imou Camera Connection Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('📹', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Kết nối Imou Camera (OpenAPI)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kết nối tài khoản Imou Life để tự động đồng bộ luồng phát và điều khiển camera từ xa.',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _imouAppIdCtrl,
                    decoration: const InputDecoration(labelText: 'Imou App ID', hintText: 'Nhập AppId từ Imou Open Platform'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _imouSecretCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Imou App Secret', hintText: 'Nhập AppSecret'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Đồng bộ'),
                          onPressed: () async {
                            final res = await ApiClient().syncImou();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res.statusCode == 200 ? 'Đã đồng bộ camera!' : 'Đồng bộ thất bại')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link, size: 16),
                          label: const Text('Lưu kết nối'),
                          onPressed: _connectImou,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
