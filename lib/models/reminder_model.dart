class ReminderModel {
  final int id;
  final int? babyId;
  final String title;
  final String content;
  final String remindAt;
  final String repeatType;
  final int? intervalHours;
  final bool isActive;
  final String? lastSentAt;

  ReminderModel({
    required this.id,
    this.babyId,
    required this.title,
    required this.content,
    required this.remindAt,
    required this.repeatType,
    this.intervalHours,
    required this.isActive,
    this.lastSentAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      babyId: json['baby_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      remindAt: json['remind_at']?.toString() ?? '',
      repeatType: json['repeat_type'] ?? 'once',
      intervalHours: json['interval_hours'],
      isActive: json['is_active'] == true,
      lastSentAt: json['last_sent_at']?.toString(),
    );
  }
}
