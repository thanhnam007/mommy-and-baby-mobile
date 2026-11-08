import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/baby_provider.dart';
import 'widgets/activity_timeline_row.dart';

class _CategoryConfig {
  final String key;
  final String label;
  final String emoji;
  final Color accent;
  final Color lightBg;
  final Color darkBg;

  const _CategoryConfig({
    required this.key,
    required this.label,
    required this.emoji,
    required this.accent,
    required this.lightBg,
    required this.darkBg,
  });
}

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  DateTime _selectedDate = DateTime.now();

  static const List<_CategoryConfig> _categories = [
    _CategoryConfig(
      key: 'all',
      label: 'Tất cả',
      emoji: '✨',
      accent: AppTheme.brand500,
      lightBg: AppTheme.brand50,
      darkBg: Color(0xFF2D1219),
    ),
    _CategoryConfig(
      key: 'feeding',
      label: 'Cữ bú',
      emoji: '🍼',
      accent: AppTheme.brand500,
      lightBg: AppTheme.brand50,
      darkBg: Color(0xFF4C0519),
    ),
    _CategoryConfig(
      key: 'solid',
      label: 'Ăn dặm',
      emoji: '🥣',
      accent: AppTheme.amber500,
      lightBg: AppTheme.amber50,
      darkBg: Color(0xFF451A03),
    ),
    _CategoryConfig(
      key: 'sleeping',
      label: 'Giấc ngủ',
      emoji: '😴',
      accent: AppTheme.indigo500,
      lightBg: AppTheme.indigo50,
      darkBg: Color(0xFF1E1B4B),
    ),
    _CategoryConfig(
      key: 'diaper',
      label: 'Thay tã',
      emoji: '🧷',
      accent: AppTheme.emerald500,
      lightBg: AppTheme.emerald50,
      darkBg: Color(0xFF064E3B),
    ),
    _CategoryConfig(
      key: 'other',
      label: 'Tắm & Khác',
      emoji: '🛁',
      accent: Color(0xFF0EA5E9),
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF0C4A6E),
    ),
  ];

  String get _dateParam =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _changeDate(int daysDelta, int babyId) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: daysDelta));
    });
    Provider.of<ActivityProvider>(context, listen: false)
        .fetchTimeline(babyId, targetDate: _dateParam);
  }

  void _jumpToToday(int babyId) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = DateTime.now();
    });
    Provider.of<ActivityProvider>(context, listen: false)
        .fetchTimeline(babyId, targetDate: _dateParam);
  }

  void _pickDate(BuildContext context, int babyId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (context.mounted) {
        Provider.of<ActivityProvider>(context, listen: false)
            .fetchTimeline(babyId, targetDate: _dateParam);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baby = babyProvider.activeBaby;

    if (baby == null) {
      return const Center(child: Text('Vui lòng chọn bé'));
    }

    final allActivities = activityProvider.allTimeline;
    final filteredActivities = activityProvider.timeline;
    final counts = activityProvider.categoryCounts;

    return RefreshIndicator(
      color: AppTheme.brand500,
      onRefresh: () => activityProvider.fetchTimeline(baby.id, targetDate: _dateParam),
      child: Column(
        children: [
          // 1. Header Zone: Date Navigation + Daily Pulse Strip + 2x3 Category Filter Grid
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray900 : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1a. Date Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 22),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _changeDate(-1, baby.id),
                        tooltip: 'Ngày trước',
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _pickDate(context, baby.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.gray800 : AppTheme.brand50.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppTheme.gray700 : AppTheme.brand200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: AppTheme.brand500,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      _isToday
                                          ? 'Hôm nay (${_selectedDate.day}/${_selectedDate.month})'
                                          : '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!_isToday) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _jumpToToday(baby.id),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brand500,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.today_rounded, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Hôm nay',
                                        style: TextStyle(
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
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 22),
                        visualDensity: VisualDensity.compact,
                        onPressed: _isToday ? null : () => _changeDate(1, baby.id),
                        tooltip: 'Ngày sau',
                      ),
                    ],
                  ),
                ),

                // 1b. Daily Rhythm Pulse Summary Strip
                if (allActivities.isNotEmpty)
                  _buildDailyPulseBar(allActivities, isDark),

                // 1c. 2x3 No-Scroll Bento Category Menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: _buildCategoryTile(
                                config: _categories[i],
                                count: counts[_categories[i].key] ?? 0,
                                isSelected: activityProvider.selectedType == _categories[i].key,
                                isDark: isDark,
                                onTap: () => _onSelectCategory(
                                  activityProvider,
                                  _categories[i].key,
                                  baby.id,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (int i = 3; i < 6; i++) ...[
                            if (i > 3) const SizedBox(width: 6),
                            Expanded(
                              child: _buildCategoryTile(
                                config: _categories[i],
                                count: counts[_categories[i].key] ?? 0,
                                isSelected: activityProvider.selectedType == _categories[i].key,
                                isDark: isDark,
                                onTap: () => _onSelectCategory(
                                  activityProvider,
                                  _categories[i].key,
                                  baby.id,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Timeline Activities Body
          Expanded(
            child: filteredActivities.isEmpty
                ? _buildEmptyState(
                    context: context,
                    activityProvider: activityProvider,
                    babyId: baby.id,
                    isDark: isDark,
                  )
                : _buildTimelineList(
                    context: context,
                    activities: filteredActivities,
                    babyId: baby.id,
                    activityProvider: activityProvider,
                    isDark: isDark,
                  ),
          ),
        ],
      ),
    );
  }

  void _onSelectCategory(ActivityProvider provider, String key, int babyId) {
    HapticFeedback.selectionClick();
    // If tapping an already-active specific category, toggle back to 'all'
    if (provider.selectedType == key && key != 'all') {
      provider.setFilterType('all', babyId);
    } else {
      provider.setFilterType(key, babyId);
    }
  }

  Widget _buildDailyPulseBar(List<ActivityModel> allActivities, bool isDark) {
    int totalMilkMl = 0;
    int feedingCount = 0;
    int totalSolidG = 0;
    int totalSleepMins = 0;
    int diaperCount = 0;

    for (final a in allActivities) {
      if (a.activityType == 'feeding') {
        feedingCount++;
        totalMilkMl += a.amountMl ?? 0;
      } else if (a.activityType == 'solid') {
        totalSolidG += a.amountMl ?? 0;
      } else if (a.activityType == 'sleeping') {
        totalSleepMins += a.durationMinutes ?? 0;
      } else if (a.activityType == 'diaper') {
        diaperCount++;
      }
    }

    final sleepHours = totalSleepMins ~/ 60;
    final sleepRemMins = totalSleepMins % 60;
    final sleepText = totalSleepMins == 0
        ? '0p'
        : (sleepHours > 0 ? '${sleepHours}g ${sleepRemMins}p' : '${sleepRemMins}p');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800.withValues(alpha: 0.65) : AppTheme.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPulseMetric('🍼', '${totalMilkMl}ml', '($feedingCount cữ)', isDark),
          _buildPulseDivider(isDark),
          _buildPulseMetric('🥣', '${totalSolidG}g', 'ăn dặm', isDark),
          _buildPulseDivider(isDark),
          _buildPulseMetric('😴', sleepText, 'ngủ', isDark),
          _buildPulseDivider(isDark),
          _buildPulseMetric('🧷', '$diaperCount', 'thay tã', isDark),
        ],
      ),
    );
  }

  Widget _buildPulseMetric(String emoji, String value, String sub, bool isDark) {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11.5)),
            const SizedBox(width: 3),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (sub.isNotEmpty)
                    TextSpan(
                      text: ' $sub',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseDivider(bool isDark) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? AppTheme.gray700 : AppTheme.gray300,
    );
  }

  Widget _buildCategoryTile({
    required _CategoryConfig config,
    required int count,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isZero = count == 0 && config.key != 'all';

    final bgColor = isSelected
        ? config.accent
        : (isDark ? AppTheme.gray800 : AppTheme.gray50);

    final borderColor = isSelected
        ? config.accent
        : (isDark ? AppTheme.gray700 : AppTheme.gray200);

    final labelColor = isSelected
        ? Colors.white
        : (isDark ? AppTheme.gray200 : AppTheme.gray800);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: (!isSelected && isZero) ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7.5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: config.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Text(config.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      config.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: -0.2,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.24)
                        : (isDark ? AppTheme.gray700 : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark ? AppTheme.gray600 : AppTheme.gray200,
                            width: 0.8,
                          ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.gray300 : config.accent),
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

  Widget _buildEmptyState({
    required BuildContext context,
    required ActivityProvider activityProvider,
    required int babyId,
    required bool isDark,
  }) {
    final isFiltered = activityProvider.selectedType != 'all';
    final selectedConfig = _categories.firstWhere(
      (c) => c.key == activityProvider.selectedType,
      orElse: () => _categories.first,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isDark ? selectedConfig.darkBg : selectedConfig.lightBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedConfig.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    isFiltered ? selectedConfig.emoji : '📋',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isFiltered
                    ? 'Chưa có bản ghi "${selectedConfig.label}" trong ngày này'
                    : 'Không có hoạt động nào trong ngày này',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFiltered
                    ? 'Mẹ có thể bấm nút (+) bên dưới để ghi thêm hoặc xem lại tất cả hoạt động.'
                    : 'Bấm nút (+) ở thanh điều hướng bên dưới để bắt đầu ghi nhật ký sinh hoạt cho bé nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.brand500,
                    side: const BorderSide(color: AppTheme.brand500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => activityProvider.setFilterType('all', babyId),
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text(
                    'Xem tất cả hoạt động',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList({
    required BuildContext context,
    required List<ActivityModel> activities,
    required int babyId,
    required ActivityProvider activityProvider,
    required bool isDark,
  }) {
    // Build grouped timeline items with Time-of-Day section headers
    final List<Widget> children = [];

    String? currentPeriodKey;
    for (int i = 0; i < activities.length; i++) {
      final act = activities[i];
      final period = _getDayPeriodInfo(act.startTime);

      if (period.key != currentPeriodKey) {
        currentPeriodKey = period.key;
        // Count how many consecutive items belong to this period block
        int periodCount = 0;
        for (int j = i; j < activities.length; j++) {
          if (_getDayPeriodInfo(activities[j].startTime).key == currentPeriodKey) {
            periodCount++;
          } else {
            break;
          }
        }
        children.add(
          _buildPeriodHeader(
            emoji: period.emoji,
            title: period.label,
            count: periodCount,
            isDark: isDark,
            isFirstSection: i == 0,
          ),
        );
      }

      final isFirstInAll = i == 0;
      final isLastInAll = i == activities.length - 1;
      final nextAct = !isLastInAll ? activities[i + 1] : null;

      children.add(
        ActivityTimelineRow(
          act: act,
          nextAct: nextAct,
          babyId: babyId,
          isFirst: isFirstInAll,
          isLast: isLastInAll,
          isDark: isDark,
          onUpdated: () {
            Provider.of<ActivityProvider>(context, listen: false)
                .fetchTimeline(babyId, targetDate: _dateParam);
          },
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 96),
      children: children,
    );
  }

  Widget _buildPeriodHeader({
    required String emoji,
    required String title,
    required int count,
    required bool isDark,
    required bool isFirstSection,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirstSection ? 2 : 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.gray100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: isDark ? AppTheme.gray200 : AppTheme.gray700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray700 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              height: 1,
              color: isDark ? AppTheme.gray800 : AppTheme.gray200,
            ),
          ),
        ],
      ),
    );
  }



  ({String key, String emoji, String label}) _getDayPeriodInfo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour;
      if (h >= 5 && h < 12) {
        return (key: 'morning', emoji: '🌅', label: 'Buổi sáng');
      } else if (h >= 12 && h < 18) {
        return (key: 'afternoon', emoji: '☀️', label: 'Buổi trưa & chiều');
      } else {
        return (key: 'night', emoji: '🌙', label: 'Buổi tối & đêm');
      }
    } catch (_) {
      return (key: 'day', emoji: '📅', label: 'Trong ngày');
    }
  }


}
