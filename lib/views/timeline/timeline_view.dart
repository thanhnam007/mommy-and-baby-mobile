import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/baby_provider.dart';
import 'activity_detail_sheet.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  DateTime _selectedDate = DateTime.now();

  String get _dateParam =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _changeDate(int daysDelta, int babyId) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: daysDelta));
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

  void _openDetail(BuildContext context, ActivityModel act, int babyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityDetailSheet(
        activity: act,
        babyId: babyId,
        onUpdated: () {
          Provider.of<ActivityProvider>(context, listen: false)
              .fetchTimeline(babyId, targetDate: _dateParam);
        },
      ),
    );
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

    final filters = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'feeding', 'label': 'Cữ bú 🍼'},
      {'key': 'solid', 'label': 'Ăn dặm 🥣'},
      {'key': 'sleeping', 'label': 'Giấc ngủ 😴'},
      {'key': 'diaper', 'label': 'Thay tã 🧷'},
      {'key': 'other', 'label': 'Khác 🎈'},
    ];

    return RefreshIndicator(
      onRefresh: () => activityProvider.fetchTimeline(baby.id, targetDate: _dateParam),
      child: Column(
        children: [
          // 1. Date Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray900 : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.gray800 : AppTheme.gray200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1, baby.id),
                  tooltip: 'Ngày trước',
                ),
                InkWell(
                  onTap: () => _pickDate(context, baby.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppTheme.brand500),
                        const SizedBox(width: 8),
                        Text(
                          _isToday ? 'Hôm nay (${_selectedDate.day}/${_selectedDate.month})' : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isToday ? null : () => _changeDate(1, baby.id),
                  tooltip: 'Ngày sau',
                ),
              ],
            ),
          ),

          // 2. Filter Pill Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = filters[index];
                final isSelected = activityProvider.selectedType == item['key'];

                return ChoiceChip(
                  label: Text(
                    item['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.gray300 : AppTheme.gray700),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.brand500,
                  backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.brand500
                        : (isDark ? AppTheme.gray700 : AppTheme.gray200),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  onSelected: (_) => activityProvider.setFilterType(item['key']!, baby.id),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 3. Timeline Activities List
          Expanded(
            child: activityProvider.timeline.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text(
                          'Không có hoạt động nào trong ngày này',
                          style: TextStyle(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
                    itemCount: activityProvider.timeline.length,
                    itemBuilder: (context, index) {
                      final act = activityProvider.timeline[index];

                      return Dismissible(
                        key: ValueKey(act.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text('Mẹ có chắc chắn muốn xóa bản ghi hoạt động này không?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
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
                          activityProvider.deleteActivity(act.id, baby.id);
                        },
                        child: InkWell(
                          onTap: () => _openDetail(context, act, baby.id),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.gray900 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(child: Text(act.icon, style: const TextStyle(fontSize: 20))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              act.title,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const Icon(Icons.edit_note, size: 16, color: Colors.grey),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatTime(act.startTime),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                        ),
                                      ),
                                      if (act.notes != null && act.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          act.notes!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    if (iso.length < 16) return iso;
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
