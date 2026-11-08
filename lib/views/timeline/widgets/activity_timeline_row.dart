import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/activity_model.dart';
import '../../../providers/activity_provider.dart';
import '../activity_detail_sheet.dart';

class ActivityCategoryConfig {
  final String key;
  final String label;
  final String emoji;
  final Color accent;
  final Color lightBg;
  final Color darkBg;

  const ActivityCategoryConfig({
    required this.key,
    required this.label,
    required this.emoji,
    required this.accent,
    required this.lightBg,
    required this.darkBg,
  });

  static const List<ActivityCategoryConfig> all = [
    ActivityCategoryConfig(
      key: 'all',
      label: 'Tất cả',
      emoji: '✨',
      accent: AppTheme.brand500,
      lightBg: AppTheme.brand50,
      darkBg: Color(0xFF2D1219),
    ),
    ActivityCategoryConfig(
      key: 'feeding',
      label: 'Cữ bú',
      emoji: '🍼',
      accent: AppTheme.brand500,
      lightBg: AppTheme.brand50,
      darkBg: Color(0xFF4C0519),
    ),
    ActivityCategoryConfig(
      key: 'solid',
      label: 'Ăn dặm',
      emoji: '🥣',
      accent: AppTheme.amber500,
      lightBg: AppTheme.amber50,
      darkBg: Color(0xFF451A03),
    ),
    ActivityCategoryConfig(
      key: 'sleeping',
      label: 'Giấc ngủ',
      emoji: '😴',
      accent: AppTheme.indigo500,
      lightBg: AppTheme.indigo50,
      darkBg: Color(0xFF1E1B4B),
    ),
    ActivityCategoryConfig(
      key: 'diaper',
      label: 'Thay tã',
      emoji: '🧷',
      accent: AppTheme.emerald500,
      lightBg: AppTheme.emerald50,
      darkBg: Color(0xFF064E3B),
    ),
    ActivityCategoryConfig(
      key: 'other',
      label: 'Tắm & Khác',
      emoji: '🛁',
      accent: Color(0xFF0EA5E9),
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF0C4A6E),
    ),
  ];

  static ActivityCategoryConfig forActivity(String activityType) {
    switch (activityType) {
      case 'feeding':
        return all[1];
      case 'solid':
        return all[2];
      case 'sleeping':
        return all[3];
      case 'diaper':
        return all[4];
      case 'bath':
      case 'play':
      default:
        return all[5];
    }
  }
}

class ActivityTimelineRow extends StatelessWidget {
  final ActivityModel act;
  final ActivityModel? nextAct;
  final int babyId;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final bool enableDismiss;
  final VoidCallback? onTap;
  final VoidCallback? onUpdated;

  const ActivityTimelineRow({
    super.key,
    required this.act,
    this.nextAct,
    required this.babyId,
    this.isFirst = false,
    this.isLast = false,
    required this.isDark,
    this.enableDismiss = true,
    this.onTap,
    this.onUpdated,
  });

  void _handleOpenDetail(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityDetailSheet(
        activity: act,
        babyId: babyId,
        onUpdated: () {
          if (onUpdated != null) {
            onUpdated!();
          } else {
            Provider.of<ActivityProvider>(context, listen: false).fetchAll(babyId);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ActivityCategoryConfig.forActivity(act.activityType);
    final isOngoing = (act.activityType == 'feeding' || act.activityType == 'sleeping') &&
        act.endTime == null;

    final startHHmm = _formatHHmm(act.startTime);
    final endHHmm = act.endTime != null ? _formatHHmm(act.endTime!) : null;
    final isOvernight = act.endTime != null &&
        (() {
          try {
            return DateTime.parse(act.endTime!).toLocal().day !=
                DateTime.parse(act.startTime).toLocal().day;
          } catch (_) {
            return false;
          }
        })();
    final badgeText = _getPrimaryMetricBadge(act);
    final tags = _getContextTags(act);
    final gapText = nextAct != null ? _calculateGapText(act.startTime, nextAct!.startTime) : null;

    final contentWidget = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column 1: Time Column (50px)
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    startHHmm,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isOngoing
                          ? config.accent
                          : (isDark ? Colors.white : AppTheme.gray900),
                    ),
                  ),
                  if (isOngoing) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Đang...',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: config.accent,
                      ),
                    ),
                  ] else if (endHHmm != null && endHHmm != startHHmm) ...[
                    const SizedBox(height: 2),
                    Text(
                      isOvernight ? '~$endHHmm (+1)' : '~$endHHmm',
                      style: TextStyle(
                        fontSize: isOvernight ? 9 : 10,
                        fontWeight: isOvernight ? FontWeight.bold : FontWeight.normal,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isOvernight
                            ? (isDark ? Colors.indigo.shade300 : AppTheme.indigo500)
                            : (isDark ? AppTheme.gray500 : AppTheme.gray400),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Column 2: Vertical Timeline Spine + Semantic Node (30px)
          SizedBox(
            width: 30,
            child: Column(
              children: [
                // Top connector segment
                Container(
                  width: 2,
                  height: 8,
                  color: isFirst
                      ? Colors.transparent
                      : (isDark ? AppTheme.gray800 : AppTheme.gray200),
                ),
                // Circular Activity Node
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? config.accent
                        : (isDark ? config.darkBg : config.lightBg),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: config.accent,
                      width: isOngoing ? 2.0 : 1.5,
                    ),
                    boxShadow: isOngoing
                        ? [
                            BoxShadow(
                              color: config.accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      act.icon,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                // Bottom connector segment
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : (isDark ? AppTheme.gray800 : AppTheme.gray200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Column 3: Semantic Event Card + Optional Time Gap Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleOpenDetail(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray900 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOngoing
                              ? config.accent.withValues(alpha: 0.7)
                              : (isDark ? AppTheme.gray800 : AppTheme.gray200),
                          width: isOngoing ? 1.4 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: config.accent,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Title + Metric Pill Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getCardHeading(act),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (badgeText != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOngoing
                                            ? config.accent
                                            : (isDark ? config.darkBg : config.lightBg),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: config.accent.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isOngoing ? Colors.white : config.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Row 2: Context Tags + Edit hint icon
                              if (tags.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: tags.map((t) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppTheme.gray800
                                                  : AppTheme.gray100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppTheme.gray300
                                                    : AppTheme.gray700,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                                    ),
                                  ],
                                ),
                              ],

                              // Row 3: Notes Quote Callout
                              if (act.notes != null && act.notes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 7),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.gray800.withValues(alpha: 0.6)
                                        : AppTheme.gray50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('📝', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          act.notes!.trim(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: isDark
                                                ? AppTheme.gray300
                                                : AppTheme.gray600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Subtle gap indicator between consecutive activities
                if (gapText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 7, left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gapText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );

    if (!enableDismiss) {
      return contentWidget;
    }

    return Dismissible(
      key: ValueKey('tl_row_${act.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Xóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Mẹ có chắc chắn muốn xóa bản ghi hoạt động này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        Provider.of<ActivityProvider>(context, listen: false).deleteActivity(act.id, babyId);
        if (onUpdated != null) {
          onUpdated!();
        }
      },
      child: contentWidget,
    );
  }

  // --- Formatting & Semantic Helpers ---

  static String _getCardHeading(ActivityModel act) {
    switch (act.activityType) {
      case 'feeding':
        return act.feedingType == 'breast' ? 'Bú mẹ trực tiếp' : 'Bú bình';
      case 'sleeping':
        return 'Giấc ngủ của bé';
      case 'solid':
        return 'Bữa ăn dặm';
      case 'diaper':
        return 'Thay tã cho bé';
      case 'bath':
        return 'Tắm mát cho bé';
      case 'play':
        return 'Vận động & Chơi';
      default:
        return act.title;
    }
  }

  static String? _getPrimaryMetricBadge(ActivityModel act) {
    switch (act.activityType) {
      case 'feeding':
        if (act.endTime == null && act.feedingType == 'breast') {
          return '🟢 ĐANG BÚ';
        }
        if (act.feedingType == 'breast') {
          final mins = act.nursingMinutes ?? act.durationMinutes;
          return mins != null ? '$mins phút' : 'Bú mẹ';
        }
        return act.amountMl != null ? '+${act.amountMl} ml' : null;
      case 'sleeping':
        if (act.endTime == null) {
          return '🟣 ĐANG NGỦ';
        }
        if (act.durationMinutes != null && act.durationMinutes! > 0) {
          final h = act.durationMinutes! ~/ 60;
          final m = act.durationMinutes! % 60;
          return h > 0 ? '${h}g ${m}p' : '$m phút';
        }
        return null;
      case 'solid':
        return act.amountMl != null ? '${act.amountMl} g' : 'Ăn dặm';
      case 'diaper':
        if (act.diaperType == 'pee') return '💧 Tè';
        if (act.diaperType == 'poop') return '💩 Ị';
        if (act.diaperType == 'both') return '💧💩 Tè + Ị';
        return '✨ Tã sạch';
      case 'bath':
        return '🛁 Sạch thơm';
      case 'play':
        return act.durationMinutes != null ? '${act.durationMinutes} phút' : '🎈 Vui vẻ';
      default:
        return null;
    }
  }

  static List<String> _getContextTags(ActivityModel act) {
    final List<String> tags = [];
    switch (act.activityType) {
      case 'feeding':
        if (act.feedingType == 'breast') {
          final sideLabel = act.breastSide == 'left'
              ? '👈 Ngực trái'
              : act.breastSide == 'right'
                  ? '👉 Ngực phải'
                  : '🔄 Cả 2 bên';
          tags.add(sideLabel);
        } else if (act.feedingType == 'bottle_breast') {
          tags.add('🧴 Sữa mẹ vắt ra');
        } else {
          tags.add('🥛 Sữa công thức');
        }
        if (act.durationMinutes != null && act.durationMinutes! > 0 && act.feedingType != 'breast') {
          tags.add('⏱ ${act.durationMinutes} phút');
        }
        break;
      case 'sleeping':
        final qLabel = act.sleepQuality == 'good'
            ? '😴 Ngủ sâu giấc'
            : act.sleepQuality == 'restless'
                ? '😣 Trằn trọc'
                : '🙂 Bình thường';
        tags.add(qLabel);
        break;
      case 'solid':
        tags.add('🥣 Cháo / Bột / Hoa quả');
        break;
      case 'diaper':
        tags.add('🧷 Vệ sinh cho bé');
        break;
      case 'bath':
        tags.add('🚿 Tắm nước ấm');
        break;
      case 'play':
        tags.add('🤸 Tummy time');
        break;
      default:
        break;
    }
    return tags;
  }

  static String _formatHHmm(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      if (iso.length >= 16) return iso.substring(11, 16);
      return iso;
    }
  }

  static String? _calculateGapText(String newerIso, String olderIso) {
    try {
      final newer = DateTime.parse(newerIso).toLocal();
      final older = DateTime.parse(olderIso).toLocal();
      final diffMins = newer.difference(older).inMinutes.abs();
      if (diffMins < 5 || diffMins > 1440) return null;
      final h = diffMins ~/ 60;
      final m = diffMins % 60;
      if (h > 0 && m > 0) {
        return 'Cách hoạt động trước ${h}g ${m}p';
      } else if (h > 0) {
        return 'Cách hoạt động trước $h giờ';
      } else {
        return 'Cách hoạt động trước $m phút';
      }
    } catch (_) {
      return null;
    }
  }
}
