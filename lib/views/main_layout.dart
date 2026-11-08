import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/baby_provider.dart';
import '../providers/growth_provider.dart';
import '../providers/theme_provider.dart';
import 'babies/baby_picker_sheet.dart';
import 'camera/camera_view.dart';
import 'dashboard/dashboard_view.dart';
import 'growth/growth_view.dart';
import 'media/media_gallery_view.dart';
import 'profile/profile_view.dart';
import 'pumping/pumping_view.dart';
import 'quick_log/quick_log_sheet.dart';
import 'reminders/reminders_view.dart';
import 'settings/server_settings_dialog.dart';
import 'timeline/timeline_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final babyProv = Provider.of<BabyProvider>(context, listen: false);
      await babyProv.fetchBabies();
      if (babyProv.activeBaby != null) {
        if (!mounted) return;
        Provider.of<ActivityProvider>(context, listen: false).fetchAll(babyProv.activeBaby!.id);
        Provider.of<GrowthProvider>(context, listen: false).fetchGrowth(babyProv.activeBaby!.id);
      }
    });
  }

  void _openQuickLog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickLogSheet(),
    );
  }

  void _openBabyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BabyPickerSheet(),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final babyProv = Provider.of<BabyProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDark;

    final baby = babyProv.activeBaby;

    final pages = [
      DashboardView(onTabChange: (idx) => setState(() => _currentTabIndex = idx)),
      const TimelineView(),
      const GrowthView(),
      const CameraView(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // 1. Top Header Bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: _openBabyPicker,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baby Emoji badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: baby?.isGirl == true
                        ? (isDark ? Colors.pink.shade900.withValues(alpha: 0.4) : const Color(0xFFFDF2F8))
                        : (isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : const Color(0xFFEFF6FF)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: baby?.isGirl == true ? Colors.pink.shade200 : Colors.blue.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: baby != null
                        ? Text(baby.genderEmoji, style: const TextStyle(fontSize: 16))
                        : Image.asset('assets/images/logo_mark.png', width: 22, height: 22, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 8),

                // Name & Age text
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              baby?.name ?? 'Chọn bé',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                        ],
                      ),
                      Text(
                        '🎂 ${baby?.ageText.isNotEmpty == true ? baby!.ageText : "Chăm sóc bé"}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brand500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Text(isDark ? '☀️' : '🌙', style: const TextStyle(fontSize: 16)),
            onPressed: () => themeProv.toggleTheme(),
            tooltip: 'Đổi chế độ Sáng / Tối',
          ),

          // Mother profile indicator (tap to open ProfileView)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                ),
                child: Row(
                  children: [
                    const Text('👩', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      auth.user?.nickname ?? auth.user?.username ?? 'Mẹ',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: ValueListenableBuilder<int>(
            valueListenable: ApiClient().activeRequestsNotifier,
            builder: (context, activeCount, _) {
              if (activeCount > 0) {
                return const LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brand500),
                );
              }
              return const SizedBox(height: 2.5);
            },
          ),
        ),
      ),

      // 2. Left Sidebar Drawer
      drawer: Drawer(
        child: Column(
          children: [
            // Header gradient with Mother Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.brand500, AppTheme.brand600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
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
                              auth.user?.fullName ?? auth.user?.username ?? 'Mẹ bỉm',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                auth.user?.isVip == true ? '👑 VIP Member' : 'Free Member',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

            // Navigation Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Text('🏠', style: TextStyle(fontSize: 18)),
                    title: const Text('Tổng quan hôm nay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: _currentTabIndex == 0,
                    selectedColor: AppTheme.brand500,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentTabIndex = 0);
                    },
                  ),
                  ListTile(
                    leading: const Text('📋', style: TextStyle(fontSize: 18)),
                    title: const Text('Dòng thời gian sinh hoạt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: _currentTabIndex == 1,
                    selectedColor: AppTheme.brand500,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentTabIndex = 1);
                    },
                  ),
                  ListTile(
                    leading: const Text('📏', style: TextStyle(fontSize: 18)),
                    title: const Text('Chiều cao & Cân nặng (WHO)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: _currentTabIndex == 2,
                    selectedColor: AppTheme.brand500,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentTabIndex = 2);
                    },
                  ),
                  ListTile(
                    leading: const Text('🍼', style: TextStyle(fontSize: 18)),
                    title: const Text('Cữ hút sữa của mẹ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PumpingView()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Text('📹', style: TextStyle(fontSize: 18)),
                    title: const Text('Real-time Tracking Baby', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    selected: _currentTabIndex == 3,
                    selectedColor: AppTheme.brand500,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentTabIndex = 3);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Text('📸', style: TextStyle(fontSize: 18)),
                    title: const Text('Kho ảnh & Video kỷ niệm (VIP)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MediaGalleryView()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Text('⏰', style: TextStyle(fontSize: 18)),
                    title: const Text('Lịch nhắc nhở bé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RemindersView()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Text('👩', style: TextStyle(fontSize: 18)),
                    title: const Text('Hồ sơ Mẹ & Bé yêu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      _openProfile();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined, size: 20),
                    title: const Text('Cài đặt Máy chủ (API)', style: TextStyle(fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const ServerSettingsDialog());
                    },
                  ),
                  ListTile(
                    leading: Text(isDark ? '☀️' : '🌙', style: const TextStyle(fontSize: 18)),
                    title: Text(isDark ? 'Chế độ Sáng' : 'Chế độ Tối', style: const TextStyle(fontSize: 13)),
                    onTap: () => themeProv.toggleTheme(),
                  ),
                ],
              ),
            ),

            // Logout Button at Bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    Navigator.pop(context);
                    await auth.logout();
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. Body View
      body: IndexedStack(
        index: _currentTabIndex,
        children: pages,
      ),

      // 4. Floating Action Button (+)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: AppTheme.brand500,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _openQuickLog,
        child: const Icon(Icons.add, size: 28),
      ),

      // 5. Bottom Navigation Bar (4 items with notch/space for FAB)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, '🏠', 'Tổng quan'),
            _buildNavItem(1, '📋', 'Sinh hoạt'),
            const SizedBox(width: 48), // Spacer for center FloatingActionButton
            _buildNavItem(2, '📏', 'Tăng trưởng'),
            _buildNavItem(3, '📹', 'BabyCam'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String emoji, String label) {
    final isSelected = _currentTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppTheme.brand500
                    : (isDark ? AppTheme.gray400 : AppTheme.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
