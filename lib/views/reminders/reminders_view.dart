import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/baby_provider.dart';
import '../../providers/reminder_provider.dart';

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
      Provider.of<ReminderProvider>(context, listen: false).fetchReminders(babyId: baby?.id);
    });
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String repeatType = 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tạo Nhắc Nhở Cho Bé ⏰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Tiêu đề nhắc nhở *', hintText: 'VD: Cho bé uống Vitamin D3'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    decoration: const InputDecoration(labelText: 'Nội dung chi tiết', hintText: 'VD: 1 giọt sau cữ bú sáng'),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.grey, width: 0.5)),
                    leading: const Icon(Icons.access_time_filled, color: AppTheme.brand500),
                    title: const Text('Giờ nhắc nhở', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.edit_calendar, size: 20),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setSheetState(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Tần suất lặp lại:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Hàng ngày'),
                        selected: repeatType == 'daily',
                        onSelected: (_) => setSheetState(() => repeatType = 'daily'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Một lần'),
                        selected: repeatType == 'once',
                        onSelected: (_) => setSheetState(() => repeatType = 'once'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Mỗi 3 giờ'),
                        selected: repeatType == 'every_x_hours',
                        onSelected: (_) => setSheetState(() => repeatType = 'every_x_hours'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;

                        final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
                        final reminderProv = Provider.of<ReminderProvider>(context, listen: false);

                        final now = DateTime.now();
                        final scheduled = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);

                        final ok = await reminderProv.createReminder({
                          if (baby != null) 'baby_id': baby.id,
                          'title': title,
                          'content': contentCtrl.text.trim().isNotEmpty ? contentCtrl.text.trim() : title,
                          'remind_at': scheduled.toUtc().toIso8601String(),
                          'repeat_type': repeatType,
                          if (repeatType == 'every_x_hours') 'interval_hours': 3,
                        }, babyId: baby?.id);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã tạo lịch nhắc nhở thành công! ⏰')),
                          );
                        }
                      },
                      child: const Text('Lưu nhắc nhở'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminderProv = Provider.of<ReminderProvider>(context);
    final baby = Provider.of<BabyProvider>(context).activeBaby;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch nhắc nhở bé'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => reminderProv.fetchReminders(babyId: baby?.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Thêm nhắc nhở'),
        onPressed: () => _showAddReminderDialog(context),
      ),
      body: reminderProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminderProv.reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('Chưa có lịch nhắc nhở nào', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'Thêm nhắc nhở để app báo mẹ đúng giờ cữ bú, uống vitamin hay tiêm phòng!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
                  itemCount: reminderProv.reminders.length,
                  itemBuilder: (context, index) {
                    final item = reminderProv.reminders[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray900 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.isActive
                                  ? AppTheme.brand500.withValues(alpha: 0.15)
                                  : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '⏰',
                                style: TextStyle(fontSize: 20, color: item.isActive ? null : Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: item.isActive ? null : TextDecoration.lineThrough,
                                    color: item.isActive ? null : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatTime(item.remindAt)} • ${item.repeatType == 'daily' ? 'Hàng ngày' : item.repeatType == 'every_x_hours' ? 'Mỗi 3 giờ' : 'Một lần'}',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                                ),
                                if (item.content.isNotEmpty && item.content != item.title)
                                  Text(
                                    item.content,
                                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_active_outlined, size: 20, color: AppTheme.brand500),
                            tooltip: 'Gửi thử thông báo',
                            onPressed: () async {
                              final ok = await reminderProv.testSend(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ok ? 'Đã kích hoạt gửi thử thông báo!' : 'Gửi thử thất bại')),
                                );
                              }
                            },
                          ),
                          Switch(
                            value: item.isActive,
                            activeTrackColor: AppTheme.brand500,
                            onChanged: (_) {
                              reminderProv.toggleReminder(item.id, babyId: baby?.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(String iso) {
    if (iso.length < 16) return iso;
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
