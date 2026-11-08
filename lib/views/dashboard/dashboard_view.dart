import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/activity_provider.dart';
import '../../providers/baby_provider.dart';
import '../../providers/growth_provider.dart';
import '../../providers/pumping_provider.dart';
import '../media/media_gallery_view.dart';
import '../pumping/pumping_view.dart';
import '../reminders/reminders_view.dart';
import '../timeline/widgets/activity_timeline_row.dart';

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
    final isCurrentlyFeeding = feeding?.isCurrentlyFeeding == true;
    final isFeedingLoading = activityProvider.isFeedingActionLoading;
    final isSleepLoading = activityProvider.isSleepActionLoading;

    final breastCount = feeding?.breastCount ?? 0;
    final bottleCount = feeding?.bottleCount ?? 0;
    final totalFeedings = breastCount + bottleCount;

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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brand500, Color(0xFFF43F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '(${baby.nickname})',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '🎂 ${baby.ageText.isNotEmpty ? baby.ageText : "Đang cập nhật"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hôm nay: ${feeding?.feedingCount ?? 0} cữ bú • ${sleep?.sleepCount ?? 0} giấc ngủ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentlyFeeding
                          ? AppTheme.brand700.withValues(alpha: 0.6)
                          : (isSleeping
                              ? Colors.indigo.shade900.withValues(alpha: 0.6)
                              : const Color(0xFF064E3B).withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCurrentlyFeeding
                                ? Colors.pinkAccent
                                : (isSleeping ? Colors.indigoAccent : const Color(0xFF34D399)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCurrentlyFeeding
                              ? 'Đang bú mẹ'
                              : (isSleeping ? 'Đang ngủ' : 'Đang thức'),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Highlight Big Cards: Cữ Bú & Cữ Ngủ (Balanced IntrinsicHeight)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Cữ Bú
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray900 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrentlyFeeding
                              ? AppTheme.brand500
                              : (isDark ? AppTheme.gray800 : AppTheme.brand100),
                          width: isCurrentlyFeeding ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isCurrentlyFeeding
                                ? AppTheme.brand500.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            activityProvider.setFilterType('feeding', baby.id);
                            onTabChange(1);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.brand500.withValues(alpha: 0.2) : AppTheme.brand50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(child: Text('🍼', style: TextStyle(fontSize: 19))),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.brand500.withValues(alpha: 0.2) : AppTheme.brand50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${feeding?.feedingCount ?? 0} cữ',
                                        style: const TextStyle(
                                          color: AppTheme.brand500,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (isCurrentlyFeeding) ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.brand500,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'Đang bú mẹ...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.brand500,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        breastCount > 0 ? '$breastCount cữ bú mẹ' : 'Hôm nay',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const Spacer(),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrentlyFeeding
                                          ? AppTheme.emerald500
                                          : (isDark ? AppTheme.brand500.withValues(alpha: 0.25) : AppTheme.brand50),
                                      foregroundColor: isCurrentlyFeeding ? Colors.white : AppTheme.brand500,
                                      elevation: 0,
                                      disabledBackgroundColor: isCurrentlyFeeding
                                          ? AppTheme.emerald500.withValues(alpha: 0.6)
                                          : (isDark ? AppTheme.brand500.withValues(alpha: 0.15) : AppTheme.brand50.withValues(alpha: 0.6)),
                                      disabledForegroundColor: isCurrentlyFeeding
                                          ? Colors.white70
                                          : AppTheme.brand500.withValues(alpha: 0.6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isCurrentlyFeeding
                                              ? AppTheme.emerald500
                                              : AppTheme.brand500.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    onPressed: isFeedingLoading
                                        ? null
                                        : () async {
                                            HapticFeedback.mediumImpact();
                                            if (isCurrentlyFeeding && feeding?.currentFeedingId != null) {
                                              DateTime start = DateTime.now();
                                              if (feeding?.currentFeedingStart != null) {
                                                try {
                                                  start = DateTime.parse(feeding!.currentFeedingStart!).toLocal();
                                                } catch (_) {}
                                              }
                                              final now = DateTime.now();
                                              final diff = now.difference(start).inMinutes;
                                              final actualMinutes = diff >= 0 ? diff : 0;
                                              await activityProvider.endBreastFeeding(
                                                baby.id,
                                                feeding!.currentFeedingId!,
                                                actualMinutes,
                                                endTime: now,
                                              );
                                            } else {
                                              await activityProvider.startBreastFeeding(baby.id, 'left');
                                            }
                                          },
                                    child: isFeedingLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: isCurrentlyFeeding ? Colors.white : AppTheme.brand500,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Đang xử lý...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          )
                                        : Text(
                                            isCurrentlyFeeding ? '✅ Kết thúc cữ bú' : '🤱 Bắt đầu cữ bú',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Card 2: Cữ Ngủ
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray900 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSleeping
                              ? AppTheme.indigo500
                              : (isDark ? AppTheme.gray800 : AppTheme.indigo50),
                          width: isSleeping ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSleeping
                                ? AppTheme.indigo500.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            activityProvider.setFilterType('sleeping', baby.id);
                            onTabChange(1);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.indigo500.withValues(alpha: 0.2) : AppTheme.indigo50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(child: Text('😴', style: TextStyle(fontSize: 19))),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.indigo500.withValues(alpha: 0.2) : AppTheme.indigo50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${sleep?.sleepCount ?? 0} giấc',
                                        style: const TextStyle(
                                          color: AppTheme.indigo500,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                Row(
                                  children: [
                                    if (isSleeping) ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'Đang ngủ ngon...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.indigo500,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Hôm nay',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const Spacer(),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSleeping
                                          ? Colors.amber.shade700
                                          : (isDark ? AppTheme.indigo500.withValues(alpha: 0.25) : AppTheme.indigo50),
                                      foregroundColor: isSleeping ? Colors.white : AppTheme.indigo500,
                                      elevation: 0,
                                      disabledBackgroundColor: isSleeping
                                          ? Colors.amber.shade700.withValues(alpha: 0.6)
                                          : (isDark ? AppTheme.indigo500.withValues(alpha: 0.15) : AppTheme.indigo50.withValues(alpha: 0.6)),
                                      disabledForegroundColor: isSleeping
                                          ? Colors.white70
                                          : AppTheme.indigo500.withValues(alpha: 0.6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isSleeping
                                              ? Colors.amber.shade600
                                              : AppTheme.indigo500.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    onPressed: isSleepLoading
                                        ? null
                                        : () async {
                                            HapticFeedback.mediumImpact();
                                            if (isSleeping && sleep?.currentSleepId != null) {
                                              await activityProvider.endSleep(baby.id, sleep!.currentSleepId!);
                                            } else {
                                              await activityProvider.startSleep(baby.id);
                                            }
                                          },
                                    child: isSleepLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: isSleeping ? Colors.white : AppTheme.indigo500,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Đang xử lý...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          )
                                        : Text(
                                            isSleeping ? '☀️ Bé đã dậy' : '💤 Bắt đầu cữ ngủ',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2b. Feeding Breakdown: Interactive Card with Ratio Bar
            Material(
              color: isDark ? AppTheme.gray900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  activityProvider.setFilterType('feeding', baby.id);
                  onTabChange(1);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
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
                              Text('🍼', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Text(
                                'Phân loại cữ bú hôm nay',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${feeding?.feedingCount ?? 0} cữ • ${feeding?.totalMl ?? 0}ml',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.brand500),
                            ],
                          ),
                        ],
                      ),
                      if (totalFeedings > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: [
                                if (breastCount > 0)
                                  Expanded(
                                    flex: breastCount,
                                    child: Container(color: const Color(0xFFEC4899)),
                                  ),
                                if (bottleCount > 0)
                                  Expanded(
                                    flex: bottleCount,
                                    child: Container(color: const Color(0xFF0284C7)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Bú mẹ trực tiếp
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF831843).withValues(alpha: 0.25) : const Color(0xFFFDF2F8),
                                borderRadius: BorderRadius.circular(14),
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
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBE185D)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFCE7F3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${feeding?.breastCount ?? 0} cữ',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9D174D)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Thời gian: ${feeding?.breastNursingMinutes ?? 0} phút',
                                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray300 : AppTheme.gray700, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Bú bình
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0369A1).withValues(alpha: 0.2) : const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(14),
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
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${feeding?.bottleCount ?? 0} cữ',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '🥛 CT: ${feeding?.formulaCount ?? 0} cữ (${feeding?.formulaMl ?? 0}ml)',
                                    style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '🧴 Mẹ: ${feeding?.bottleBreastCount ?? 0} cữ (${feeding?.bottleBreastMl ?? 0}ml)',
                                    style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
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
              ),
            ),
            const SizedBox(height: 14),

            // 3. BabyCam Live Card
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTabChange(3);
                },
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
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
                      const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Bento Grid 2x2 for Utility Cards (WHO Growth, Pumping, VIP Photos, Reminders)
            Row(
              children: [
                // 4a. WHO Growth Card
                Expanded(
                  child: Material(
                    color: isDark ? AppTheme.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTabChange(2);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
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
                                    color: Colors.teal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text('📏', style: TextStyle(fontSize: 18))),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tăng trưởng WHO',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              growthProvider.summary?.latestRecord != null
                                  ? '${growthProvider.summary!.latestRecord!.weightKg ?? "--"}kg • ${growthProvider.summary!.latestRecord!.heightCm ?? "--"}cm'
                                  : 'Chuẩn phát triển',
                              style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 4b. Pumping Card
                Expanded(
                  child: Material(
                    color: isDark ? AppTheme.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PumpingView()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.brand100),
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
                                    color: AppTheme.brand500.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text('🍼', style: TextStyle(fontSize: 18))),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Hút sữa của mẹ',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pumpingProvider.todaySummary != null
                                  ? '${pumpingProvider.todaySummary!.todayTotalMl} ml (${pumpingProvider.todaySummary!.todaySessionsCount} cữ)'
                                  : 'Sản lượng sữa mẹ',
                              style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // 4c. VIP Photo Gallery Card
                Expanded(
                  child: Material(
                    color: isDark ? AppTheme.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MediaGalleryView()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
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
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text('📸', style: TextStyle(fontSize: 18))),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Kho ảnh VIP',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lưu giữ kỷ niệm',
                              style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 4d. Reminders Card
                Expanded(
                  child: Material(
                    color: isDark ? AppTheme.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RemindersView()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
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
                                    color: AppTheme.brand500.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text('⏰', style: TextStyle(fontSize: 18))),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Nhắc nhở bé',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bú, ngủ, vitamin...',
                              style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Recent Activities Header & Timeline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🕒', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      'Hoạt động gần nhất',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    activityProvider.setFilterType('all', baby.id);
                    onTabChange(1);
                  },
                  child: const Text('Xem tất cả →', style: TextStyle(fontSize: 12.5, color: AppTheme.brand500, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Activities Timeline Rows
            if (activityProvider.allTimeline.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray900 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                ),
                child: Center(
                  child: Text(
                    'Chưa có hoạt động nào trong hôm nay.\nBấm nút (+) ở dưới để ghi cữ nhé mẹ!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final recentActs = activityProvider.allTimeline.take(5).toList();
                  return Column(
                    children: List.generate(recentActs.length, (index) {
                      final act = recentActs[index];
                      final nextAct = index < recentActs.length - 1 ? recentActs[index + 1] : null;
                      return ActivityTimelineRow(
                        key: ValueKey('dash_act_${act.id}_${act.activityType}'),
                        act: act,
                        nextAct: nextAct,
                        babyId: baby.id,
                        isFirst: index == 0,
                        isLast: index == recentActs.length - 1,
                        isDark: isDark,
                        enableDismiss: true,
                        onUpdated: () => activityProvider.fetchAll(baby.id),
                      );
                    }),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
