import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/activity_provider.dart';
import '../../providers/baby_provider.dart';
import '../../providers/growth_provider.dart';
import '../../providers/pumping_provider.dart';
import '../media/media_gallery_view.dart';
import '../pumping/pumping_view.dart';
import '../reminders/reminders_view.dart';
import '../timeline/activity_detail_sheet.dart';

class DashboardView extends StatelessWidget {
  final Function(int) onTabChange;

  const DashboardView({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final growthProvider = Provider.of<GrowthProvider>(context);
    final pumpingProvider = Provider.of<PumpingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baby = babyProvider.activeBaby;

    if (baby == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👶', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Bạn chưa thêm thông tin bé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Hãy thêm thông tin bé để bắt đầu theo dõi cữ bú, giấc ngủ!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
              ),
            ],
          ),
        ),
      );
    }

    final feeding = activityProvider.feedingSummary;
    final sleep = activityProvider.sleepSummary;
    final isSleeping = activityProvider.isSleeping;

    return RefreshIndicator(
      onRefresh: () async {
        await activityProvider.fetchAll(baby.id);
        await growthProvider.fetchGrowth(baby.id);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Baby Status Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brand500, Color(0xFFF43F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brand500.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(baby.genderEmoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                baby.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (baby.nickname != null && baby.nickname!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '(${baby.nickname})',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '🎂 ${baby.ageText.isNotEmpty ? baby.ageText : "Đang cập nhật"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSleeping ? Colors.indigo.shade900.withValues(alpha: 0.5) : const Color(0xFF064E3B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSleeping ? Colors.indigoAccent : const Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSleeping ? 'Đang ngủ' : 'Đang thức',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Highlight Big Cards: Cữ Bú & Cữ Ngủ
            Row(
              children: [
                // Card 1: Cữ Bú
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray900 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.brand100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.brand500.withValues(alpha: 0.2) : AppTheme.brand50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('🍼', style: TextStyle(fontSize: 18))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.brand500.withValues(alpha: 0.2) : AppTheme.brand50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${feeding?.feedingCount ?? 0} cữ',
                                style: const TextStyle(color: AppTheme.brand500, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${feeding?.totalMl ?? 0}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ml sữa',
                              style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feeding?.isCurrentlyFeeding == true ? 'Đang bú...' : 'Hôm nay',
                          style: TextStyle(
                            fontSize: 11,
                            color: feeding?.isCurrentlyFeeding == true ? AppTheme.brand500 : (isDark ? AppTheme.gray400 : AppTheme.gray500),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if (feeding?.isCurrentlyFeeding == true && feeding?.currentFeedingId != null) {
                              await activityProvider.endBreastFeeding(baby.id, feeding!.currentFeedingId!, 15);
                            } else {
                              await activityProvider.startBreastFeeding(baby.id, 'left');
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: feeding?.isCurrentlyFeeding == true
                                  ? AppTheme.emerald500
                                  : (isDark ? AppTheme.brand500.withValues(alpha: 0.2) : AppTheme.brand50),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: feeding?.isCurrentlyFeeding == true
                                    ? AppTheme.emerald500
                                    : AppTheme.brand500.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              feeding?.isCurrentlyFeeding == true ? '✅ Kết thúc cữ bú' : '🤱 Bắt đầu cữ bú',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: feeding?.isCurrentlyFeeding == true ? Colors.white : AppTheme.brand500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Card 2: Cữ Ngủ
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray900 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.indigo50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.indigo500.withValues(alpha: 0.2) : AppTheme.indigo50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('😴', style: TextStyle(fontSize: 18))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.indigo500.withValues(alpha: 0.2) : AppTheme.indigo50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${sleep?.sleepCount ?? 0} giấc',
                                style: const TextStyle(color: AppTheme.indigo500, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sleep?.totalSleepFormatted ?? '0g 0p',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sleep?.isCurrentlySleeping == true ? 'Đang ngủ ngon' : 'Hôm nay',
                          style: TextStyle(
                            fontSize: 11,
                            color: sleep?.isCurrentlySleeping == true ? AppTheme.indigo500 : (isDark ? AppTheme.gray400 : AppTheme.gray500),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if (sleep?.isCurrentlySleeping == true && sleep?.currentSleepId != null) {
                              await activityProvider.endSleep(baby.id, sleep!.currentSleepId!);
                            } else {
                              await activityProvider.startSleep(baby.id);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sleep?.isCurrentlySleeping == true
                                  ? Colors.amber.shade700
                                  : (isDark ? AppTheme.indigo500.withValues(alpha: 0.2) : AppTheme.indigo50),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sleep?.isCurrentlySleeping == true
                                    ? Colors.amber.shade600
                                    : AppTheme.indigo500.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              sleep?.isCurrentlySleeping == true ? '☀️ Bé đã dậy' : '💤 Bắt đầu cữ ngủ',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: sleep?.isCurrentlySleeping == true ? Colors.white : AppTheme.indigo500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2b. Feeding Breakdown: Bú mẹ riêng & Bú bình riêng (Sữa CT & Sữa mẹ)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.brand100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('🍼', style: TextStyle(fontSize: 15)),
                          SizedBox(width: 6),
                          Text(
                            'Phân loại cữ bú hôm nay',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${feeding?.feedingCount ?? 0} cữ (${feeding?.totalMl ?? 0}ml)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Bú mẹ trực tiếp
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF831843).withValues(alpha: 0.25) : const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF9D174D).withValues(alpha: 0.5) : const Color(0xFFFCE7F3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '🤱 Bú mẹ',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFBE185D)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCE7F3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${feeding?.breastCount ?? 0} cữ',
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF9D174D)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian: ${feeding?.breastNursingMinutes ?? 0} phút',
                                style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bú bình
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0369A1).withValues(alpha: 0.2) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFFE0F2FE),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '🍼 Bú bình',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${feeding?.bottleCount ?? 0} cữ',
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '🥛 Sữa CT: ${feeding?.formulaCount ?? 0} cữ (${feeding?.formulaMl ?? 0}ml)',
                                style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '🧴 Sữa mẹ: ${feeding?.bottleBreastCount ?? 0} cữ (${feeding?.bottleBreastMl ?? 0}ml)',
                                style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. BabyCam Live Banner Card
            InkWell(
              onTap: () => onTabChange(3), // Navigate to BabyCam tab
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.brand500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.brand500.withValues(alpha: 0.4)),
                      ),
                      child: const Center(child: Text('📹', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BabyCam Trực Tiếp',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 6),
                              Text('🔴 LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Giám sát hình ảnh & chuyển động thời gian thực',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Growth Tracker Card
            InkWell(
              onTap: () => onTabChange(2), // Navigate to Growth tab
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray900 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('📏', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chiều cao & Cân nặng (WHO)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            growthProvider.summary?.latestRecord != null
                                ? 'Mới nhất: ${growthProvider.summary!.latestRecord!.weightKg ?? "--"} kg • ${growthProvider.summary!.latestRecord!.heightCm ?? "--"} cm'
                                : 'Theo dõi chỉ số phát triển theo chuẩn WHO',
                            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Pumping (Hút sữa mẹ) Card
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PumpingView()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray900 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.brand100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.brand500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('🍼', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cữ Hút Sữa Của Mẹ',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pumpingProvider.todaySummary != null
                                ? 'Hôm nay: ${pumpingProvider.todaySummary!.todayTotalMl} ml (${pumpingProvider.todaySummary!.todaySessionsCount} cữ)'
                                : 'Theo dõi cữ hút và sản lượng sữa mẹ',
                            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Two Quick Cards: Kho ảnh & Lịch nhắc nhở
            Row(
              children: [
                // Kho ảnh VIP Card
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MediaGalleryView()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray900 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('📸', style: TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Kho ảnh VIP',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lưu giữ kỷ niệm',
                            style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Lịch nhắc nhở Card
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RemindersView()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray900 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.brand500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('⏰', style: TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nhắc nhở bé',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cữ bú, vitamin...',
                            style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Recent Activities Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động gần nhất',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => onTabChange(1), // Timeline tab
                  child: const Text('Xem tất cả →', style: TextStyle(fontSize: 12, color: AppTheme.brand500)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Activity preview items
            if (activityProvider.timeline.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                ),
                child: Center(
                  child: Text(
                    'Chưa có hoạt động nào trong hôm nay.\nBấm nút (+) ở dưới để ghi cữ nhé mẹ!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                  ),
                ),
              )
            else
              ...activityProvider.timeline.take(5).map((act) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => ActivityDetailSheet(
                            activity: act,
                            babyId: baby.id,
                            onUpdated: () => activityProvider.fetchAll(baby.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(act.icon, style: const TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  if (act.notes != null && act.notes!.isNotEmpty)
                                    Text(
                                      act.notes!,
                                      style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  act.startTime.length >= 16 ? act.startTime.substring(11, 16) : '',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Chi tiết →',
                                  style: TextStyle(fontSize: 10, color: AppTheme.brand500, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
