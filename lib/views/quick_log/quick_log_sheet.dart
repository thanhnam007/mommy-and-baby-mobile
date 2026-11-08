import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/activity_provider.dart';
import '../../providers/baby_provider.dart';

class QuickLogSheet extends StatefulWidget {
  const QuickLogSheet({super.key});

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  String? _selectedAction; // 'bottle', 'solid', 'sleep', 'breast', 'diaper', 'bath', 'play'

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // Bottle
  final _amountMlController = TextEditingController(text: '120');

  // Solid (Ăn dặm)
  final _solidAmountController = TextEditingController(text: '80');

  // Breast
  String _breastSide = 'left';
  final _breastMinutesController = TextEditingController();

  // Sleep
  String _sleepQuality = 'good';

  // Diaper
  String _diaperType = 'both';

  // Notes
  final _notesController = TextEditingController();

  // Loading state flags
  bool _isSubmitting = false;
  bool _isSleepingToggleLoading = false;
  bool _isFeedingToggleLoading = false;

  @override
  void dispose() {
    _amountMlController.dispose();
    _solidAmountController.dispose();
    _breastMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initAction(String action) {
    setState(() {
      _selectedAction = action;
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      // For sleep and breast, default end time to null (ongoing) so user can explicitly pick or leave empty
      if (action == 'sleep' || action == 'breast') {
        _endDate = null;
        _endTime = null;
        if (action == 'breast') {
          _breastMinutesController.text = '';
        }
      } else {
        _endDate = _startDate;
        _endTime = _startTime;
      }
    });
  }

  void _syncBreastEndTimeFromMinutes(int mins) {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final end = start.add(Duration(minutes: mins));
    setState(() {
      _endDate = DateTime(end.year, end.month, end.day);
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    });
  }

  void _syncBreastMinutesFromEnd() {
    if (_endTime == null) {
      _breastMinutesController.text = '';
      return;
    }
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final ed = _endDate ?? _startDate;
    final end = DateTime(ed.year, ed.month, ed.day, _endTime!.hour, _endTime!.minute);
    final diff = end.difference(start).inMinutes;
    _breastMinutesController.text = (diff >= 0 ? diff : 0).toString();
  }

  void _pickStartDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (pickedTime == null) return;

    setState(() {
      _startDate = pickedDate;
      _startTime = pickedTime;
      if (_selectedAction == 'breast') {
        final mins = int.tryParse(_breastMinutesController.text.trim());
        if (mins != null && mins >= 0) {
          final start = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          final end = start.add(Duration(minutes: mins));
          _endDate = DateTime(end.year, end.month, end.day);
          _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
        } else if (_endTime != null) {
          _syncBreastMinutesFromEnd();
        }
      }
    });
  }

  void _pickEndTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _endTime = pickedTime;
      if (_selectedAction == 'sleep') {
        if (pickedTime.hour < _startTime.hour || (pickedTime.hour == _startTime.hour && pickedTime.minute < _startTime.minute)) {
          _endDate = _startDate.add(const Duration(days: 1));
        } else if (_endDate == null) {
          _endDate = _startDate;
        }
      } else {
        _endDate = _startDate;
      }
      if (_selectedAction == 'breast') {
        _syncBreastMinutesFromEnd();
      }
    });
  }

  void _pickEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate.subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    setState(() {
      _endDate = pickedDate;
      if (_endTime == null) _endTime = TimeOfDay.now();
      if (_selectedAction == 'breast') {
        _syncBreastMinutesFromEnd();
      }
    });
  }

  int _calculateDuration() {
    if (_endTime == null) return 0;
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final ed = _endDate ?? _startDate;
    var end = DateTime(ed.year, ed.month, ed.day, _endTime!.hour, _endTime!.minute);
    if (_endDate == null && end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  void _submit(BuildContext context) async {
    if (_isSubmitting) return;

    final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
    if (baby == null) return;

    setState(() => _isSubmitting = true);
    final activity = Provider.of<ActivityProvider>(context, listen: false);
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime? endDateTime;
    if (_endTime != null) {
      final ed = _endDate ?? _startDate;
      endDateTime = DateTime(
        ed.year,
        ed.month,
        ed.day,
        _endTime!.hour,
        _endTime!.minute,
      );
      if (_endDate == null && endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
    }

    try {
      bool ok = false;
      if (_selectedAction == 'bottle') {
        final ml = int.tryParse(_amountMlController.text) ?? 100;
        ok = await activity.logBottleFeeding(baby.id, ml, time: startDateTime, notes: notes);
      } else if (_selectedAction == 'solid') {
        final grams = int.tryParse(_solidAmountController.text) ?? 80;
        ok = await activity.logSolid(baby.id, grams, time: startDateTime, notes: notes);
      } else if (_selectedAction == 'sleep') {
        if (endDateTime == null) {
          // Ongoing sleep
          ok = await activity.startSleep(baby.id, startTime: startDateTime, notes: notes);
        } else {
          ok = await activity.manualSleep(baby.id, startDateTime, endDateTime, sleepQuality: _sleepQuality, notes: notes);
        }
      } else if (_selectedAction == 'breast') {
        if (endDateTime == null) {
          // Ongoing breast feeding
          ok = await activity.startBreastFeeding(baby.id, _breastSide, startTime: startDateTime, notes: notes);
        } else {
          int durationMins = 0;
          if (_breastMinutesController.text.trim().isNotEmpty) {
            durationMins = int.tryParse(_breastMinutesController.text.trim()) ?? 0;
          } else {
            final diff = endDateTime.difference(startDateTime).inMinutes;
            durationMins = diff >= 0 ? diff : 0;
          }
          ok = await activity.manualBreastFeeding(
            baby.id,
            startDateTime,
            endDateTime,
            side: _breastSide,
            minutes: durationMins,
            notes: notes,
          );
        }
      } else if (_selectedAction == 'diaper') {
        ok = await activity.logDiaper(baby.id, _diaperType, time: startDateTime, notes: notes);
      } else if (_selectedAction == 'bath') {
        ok = await activity.logBath(baby.id, time: startDateTime, notes: notes);
      } else if (_selectedAction == 'play') {
        ok = await activity.logPlay(baby.id, 20, time: startDateTime, notes: notes);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã ghi nhận cữ sinh hoạt thành công! 🎉' : 'Đã có lỗi xảy ra'),
            backgroundColor: ok ? AppTheme.emerald500 : Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activity = Provider.of<ActivityProvider>(context);
    final baby = Provider.of<BabyProvider>(context).activeBaby;

    if (baby == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Vui lòng chọn hoặc thêm bé trước khi ghi hoạt động'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedAction == null ? 'Ghi nhanh cữ sinh hoạt 🍼' : _getActionTitle(_selectedAction!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_selectedAction != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () => setState(() => _selectedAction = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Action Grid (if nothing selected)
            if (_selectedAction == null) ...[
              // 1. Two Quick Live Action Cards: Ngủ & Bú Mẹ
              // Card 1: Giấc ngủ
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: activity.isSleeping
                      ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF))
                      : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activity.isSleeping ? AppTheme.indigo500 : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('😴', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activity.isSleeping ? 'Bé đang ngủ ngon...' : 'Giấc ngủ của bé',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (activity.isSleeping) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.isSleeping
                                ? 'Bắt đầu lúc ${_formatTime(activity.sleepSummary?.currentSleepStart)}'
                                : 'Bấm để bắt đầu tính giờ bé ngủ',
                            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activity.isSleeping ? Colors.amber.shade700 : AppTheme.indigo500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSleepingToggleLoading
                          ? null
                          : () async {
                              setState(() => _isSleepingToggleLoading = true);
                              try {
                                if (activity.isSleeping && activity.sleepSummary?.currentSleepId != null) {
                                  await activity.endSleep(baby.id, activity.sleepSummary!.currentSleepId!);
                                } else {
                                  await activity.startSleep(baby.id);
                                }
                                if (context.mounted) Navigator.of(context).pop();
                              } finally {
                                if (mounted) {
                                  setState(() => _isSleepingToggleLoading = false);
                                }
                              }
                            },
                      child: _isSleepingToggleLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              activity.isSleeping ? 'Bé đã dậy ☀️' : 'Bắt đầu cữ ngủ',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),

              // Card 2: Bú Mẹ
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: activity.isFeeding
                      ? (isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2))
                      : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activity.isFeeding ? AppTheme.brand500 : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🤱', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activity.isFeeding ? 'Bé đang bú mẹ...' : 'Bú mẹ trực tiếp',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (activity.isFeeding) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppTheme.emerald500, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.isFeeding
                                ? 'Bắt đầu lúc ${_formatTime(activity.feedingSummary?.currentFeedingStart)}'
                                : 'Bấm để bắt đầu tính giờ cữ bú',
                            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activity.isFeeding ? AppTheme.emerald500 : AppTheme.brand500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isFeedingToggleLoading
                          ? null
                          : () async {
                              setState(() => _isFeedingToggleLoading = true);
                              try {
                                if (activity.isFeeding && activity.feedingSummary?.currentFeedingId != null) {
                                  DateTime start = DateTime.now();
                                  if (activity.feedingSummary?.currentFeedingStart != null) {
                                    try {
                                      start = DateTime.parse(activity.feedingSummary!.currentFeedingStart!).toLocal();
                                    } catch (_) {}
                                  }
                                  final now = DateTime.now();
                                  final diff = now.difference(start).inMinutes;
                                  final actualMinutes = diff >= 0 ? diff : 0;
                                  await activity.endBreastFeeding(
                                    baby.id,
                                    activity.feedingSummary!.currentFeedingId!,
                                    actualMinutes,
                                    endTime: now,
                                  );
                                } else {
                                  await activity.startBreastFeeding(baby.id, 'left');
                                }
                                if (context.mounted) Navigator.of(context).pop();
                              } finally {
                                if (mounted) {
                                  setState(() => _isFeedingToggleLoading = false);
                                }
                              }
                            },
                      child: _isFeedingToggleLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              activity.isFeeding ? 'Kết thúc cữ bú' : 'Bắt đầu cữ bú mẹ',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppTheme.gray800 : AppTheme.gray200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Hoặc tạo sinh hoạt thủ công',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? AppTheme.gray800 : AppTheme.gray200)),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  _buildQuickCard('😴', 'Cữ ngủ', () => _initAction('sleep')),
                  _buildQuickCard('🤱', 'Bú mẹ', () => _initAction('breast')),
                  _buildQuickCard('🍼', 'Bú bình', () => _initAction('bottle')),
                  _buildQuickCard('🥣', 'Ăn dặm', () => _initAction('solid')),
                  _buildQuickCard('🧷', 'Thay tã', () => _initAction('diaper')),
                  _buildQuickCard('🛁', 'Tắm bé', () => _initAction('bath')),
                ],
              ),
            ] else ...[
              // Date & Time Picker Row for any activity (Start Time)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                  ),
                  leading: const Icon(Icons.access_time_rounded, color: AppTheme.brand500, size: 20),
                  title: Text(
                    _selectedAction == 'sleep' || _selectedAction == 'breast' ? 'Thời gian bắt đầu' : 'Thời gian ghi cữ',
                    style: const TextStyle(fontSize: 11),
                  ),
                  subtitle: Text(
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')} • ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.edit_calendar, size: 18),
                  onTap: () => _pickStartDateTime(context),
                ),
              ),
              const SizedBox(height: 10),

              // End Time Picker (specifically for sleep and breast feeding, allows null/empty for ongoing!)
              if (_selectedAction == 'sleep' || _selectedAction == 'breast') ...[
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                    ),
                    leading: Icon(
                      _endTime == null
                          ? Icons.hourglass_top_rounded
                          : (_selectedAction == 'sleep' ? Icons.wb_sunny_rounded : Icons.flag_rounded),
                      color: _endTime == null ? Colors.amber.shade700 : AppTheme.emerald500,
                      size: 20,
                    ),
                    title: Text(
                      _selectedAction == 'sleep' ? 'Thời gian thức dậy' : 'Thời gian kết thúc',
                      style: const TextStyle(fontSize: 11),
                    ),
                    subtitle: Text(
                      _endTime != null
                          ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')} • ${_endDate?.day ?? _startDate.day}/${_endDate?.month ?? _startDate.month}/${_endDate?.year ?? _startDate.year}'
                          : 'Để trống (Đang trong cữ chưa kết thúc)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _endTime == null ? Colors.amber.shade700 : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_endTime != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            tooltip: 'Để trống giờ kết thúc',
                            onPressed: () {
                              setState(() {
                                _endTime = null;
                                if (_selectedAction == 'breast') {
                                  _breastMinutesController.text = '';
                                }
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.event_available, size: 18, color: AppTheme.brand500),
                          tooltip: _selectedAction == 'sleep' ? 'Chọn ngày thức dậy' : 'Chọn ngày kết thúc',
                          onPressed: () => _pickEndDate(context),
                        ),
                        const Icon(Icons.more_time_rounded, size: 18),
                      ],
                    ),
                    onTap: () => _pickEndTime(context),
                  ),
                ),
                if (_selectedAction == 'sleep' && _endTime != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Ngày thức dậy:',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                      ),
                      ChoiceChip(
                        label: Text('🌙 Cùng ngày (${_startDate.day}/${_startDate.month})', style: const TextStyle(fontSize: 11)),
                        selected: _endDate == null || (_endDate!.year == _startDate.year && _endDate!.month == _startDate.month && _endDate!.day == _startDate.day),
                        onSelected: (sel) {
                          if (sel) setState(() => _endDate = _startDate);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('☀️ Hôm sau (+1 ngày)', style: TextStyle(fontSize: 11)),
                        selected: _endDate != null && _endDate!.difference(_startDate).inDays == 1,
                        onSelected: (sel) {
                          if (sel) setState(() => _endDate = _startDate.add(const Duration(days: 1)));
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                // Helper badge indicating status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _endTime == null
                        ? Colors.amber.shade900.withValues(alpha: 0.12)
                        : AppTheme.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _endTime == null ? Icons.info_outline : Icons.check_circle_outline,
                        size: 15,
                        color: _endTime == null ? Colors.amber.shade800 : AppTheme.emerald500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _endTime == null
                              ? 'Cữ sẽ được ghi nhận là ĐANG DIỄN RA (chưa kết thúc).'
                              : 'Cữ đã hoàn thành (Thời lượng: ${_calculateDuration()} phút).',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _endTime == null ? Colors.amber.shade800 : AppTheme.emerald500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Form for Selected Action
              if (_selectedAction == 'bottle') ...[
                const Text('Lượng sữa bú (ml):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountMlController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: 'ml',
                    prefixIcon: Icon(Icons.water_drop_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [60, 90, 120, 150, 180].map((ml) {
                    return ActionChip(
                      label: Text('$ml ml', style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _amountMlController.text = ml.toString()),
                    );
                  }).toList(),
                ),
              ] else if (_selectedAction == 'solid') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lượng ăn dặm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      '${_solidAmountController.text} ml / gam',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [30, 50, 80, 100, 120, 150, 200, 250].map((g) {
                    final isSel = _solidAmountController.text == g.toString();
                    return ChoiceChip(
                      label: Text('${g}g', style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      selectedColor: Colors.amber.shade600,
                      onSelected: (_) => setState(() => _solidAmountController.text = g.toString()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _solidAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Hoặc tự gõ số lượng (ml / gam)...',
                    suffixText: 'g',
                    prefixIcon: Icon(Icons.restaurant, size: 20, color: Colors.amber),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else if (_selectedAction == 'sleep') ...[
                const Text('Chất lượng giấc ngủ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    {'key': 'good', 'label': '😴 Ngoan / Sâu giấc'},
                    {'key': 'normal', 'label': '🙂 Bình thường'},
                    {'key': 'restless', 'label': '😣 Trằn trọc / Khó ngủ'},
                  ].map((q) {
                    final isSel = _sleepQuality == q['key'];
                    return ChoiceChip(
                      label: Text(q['label']!, style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      selectedColor: AppTheme.indigo500,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? AppTheme.gray300 : AppTheme.gray700),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _sleepQuality = q['key']!),
                    );
                  }).toList(),
                ),
              ] else if (_selectedAction == 'breast') ...[
                const Text('Bên ngực bú:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    {'key': 'left', 'label': 'Ngực Trái 👈'},
                    {'key': 'right', 'label': 'Ngực Phải 👉'},
                    {'key': 'both', 'label': 'Cả hai bên 🔄'},
                  ].map((s) {
                    final isSel = _breastSide == s['key'];
                    return ChoiceChip(
                      label: Text(s['label']!, style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      selectedColor: AppTheme.brand500,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? AppTheme.gray300 : AppTheme.gray700),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _breastSide = s['key']!),
                    );
                  }).toList(),
                ),
                if (_endTime != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời gian bú (phút):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        'Đồng bộ với giờ kết thúc',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [0, 5, 10, 15, 20, 25, 30].map((m) {
                      final isSel = _breastMinutesController.text.trim() == m.toString();
                      return ActionChip(
                        label: Text('$m p', style: const TextStyle(fontSize: 11)),
                        backgroundColor: isSel ? AppTheme.brand500.withValues(alpha: 0.15) : null,
                        side: isSel ? const BorderSide(color: AppTheme.brand500) : null,
                        onPressed: () {
                          _breastMinutesController.text = m.toString();
                          _syncBreastEndTimeFromMinutes(m);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _breastMinutesController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final mins = int.tryParse(val.trim());
                      if (mins != null && mins >= 0) {
                        _syncBreastEndTimeFromMinutes(mins);
                      }
                    },
                    decoration: const InputDecoration(
                      suffixText: 'phút',
                      prefixIcon: Icon(Icons.timer_outlined, size: 20),
                      hintText: 'Nhập số phút bú, giờ kết thúc sẽ tự động nhảy...',
                    ),
                  ),
                ],
              ] else if (_selectedAction == 'diaper') ...[
                const Text('Loại tã thay:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('💧 Tè')),
                        selected: _diaperType == 'pee',
                        onSelected: (val) => setState(() => _diaperType = 'pee'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('💩 Ị')),
                        selected: _diaperType == 'poop',
                        onSelected: (val) => setState(() => _diaperType = 'poop'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('💧💩 Cả hai')),
                        selected: _diaperType == 'both',
                        onSelected: (val) => setState(() => _diaperType = 'both'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: _selectedAction == 'solid' ? 'Món ăn dặm & phản ứng của bé' : 'Ghi chú thêm (tùy chọn)',
                  hintText: _selectedAction == 'solid' ? 'VD: Cháo bí đỏ thịt bằm, bột yến mạch, bé ăn rất hợp tác...' : null,
                  prefixIcon: Icon(_selectedAction == 'solid' ? Icons.restaurant_menu : Icons.note_alt_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: _selectedAction == 'solid'
                      ? ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700)
                      : (_selectedAction == 'sleep'
                          ? ElevatedButton.styleFrom(backgroundColor: AppTheme.indigo500)
                          : null),
                  onPressed: _isSubmitting ? null : () => _submit(context),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đang ghi nhận...',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          _getSubmitButtonText(_selectedAction!),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'sleep':
        return 'Ghi nhận Giấc ngủ 😴';
      case 'breast':
        return 'Ghi nhận Bú mẹ trực tiếp 🤱';
      case 'bottle':
        return 'Ghi nhận Bú bình 🍼';
      case 'solid':
        return 'Ghi nhận Ăn dặm 🥣';
      case 'diaper':
        return 'Ghi nhận Thay tã 🧷';
      case 'bath':
        return 'Ghi nhận Tắm bé 🛁';
      case 'play':
        return 'Ghi nhận Vận động 🎈';
      default:
        return 'Chi tiết cữ sinh hoạt';
    }
  }

  String _getSubmitButtonText(String action) {
    switch (action) {
      case 'sleep':
        return _endTime == null ? 'Bắt đầu cữ ngủ (Đang diễn ra) 😴' : 'Lưu cữ ngủ 💾';
      case 'breast':
        return _endTime == null ? 'Bắt đầu cữ bú mẹ (Đang diễn ra) 🤱' : 'Lưu cữ bú mẹ 💾';
      case 'solid':
        return 'Lưu bữa ăn dặm 🥣';
      default:
        return 'Lưu cữ ngay 💾';
    }
  }

  Widget _buildQuickCard(String emoji, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray800 : AppTheme.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
