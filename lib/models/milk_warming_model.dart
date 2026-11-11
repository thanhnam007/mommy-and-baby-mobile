class MilkWarmingRecordModel {
  final int id;
  final int userId;
  final int? babyId;
  final String startTime;
  final String? endTime;
  final int amountMl;
  final int durationSeconds;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  MilkWarmingRecordModel({
    required this.id,
    required this.userId,
    this.babyId,
    required this.startTime,
    this.endTime,
    required this.amountMl,
    required this.durationSeconds,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MilkWarmingRecordModel.fromJson(Map<String, dynamic> json) {
    return MilkWarmingRecordModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      babyId: json['baby_id'] is int ? json['baby_id'] : int.tryParse(json['baby_id']?.toString() ?? ''),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString(),
      amountMl: json['amount_ml'] is int ? json['amount_ml'] : int.tryParse(json['amount_ml'].toString()) ?? 0,
      durationSeconds: json['duration_seconds'] is int ? json['duration_seconds'] : int.tryParse(json['duration_seconds']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'completed',
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  DateTime? get startDateTime => DateTime.tryParse(startTime);
  DateTime? get endDateTime => endTime != null ? DateTime.tryParse(endTime!) : null;

  String formatDuration() {
    final sec = durationSeconds;
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0) return '${m}p ${s}s';
    return '${s}s';
  }
}

class MilkWarmingStatusModel {
  final MilkWarmingRecordModel? activeWarming;
  final int? activeDurationSeconds;
  final MilkWarmingRecordModel? lastCompletedWarming;
  final int? secondsSinceLastWarming;
  final int? minutesSinceLastWarming;
  final bool isOver2Hours;
  final String statusLabel;
  final String displayMessage;
  final int? safeRemainingSeconds;

  MilkWarmingStatusModel({
    this.activeWarming,
    this.activeDurationSeconds,
    this.lastCompletedWarming,
    this.secondsSinceLastWarming,
    this.minutesSinceLastWarming,
    this.isOver2Hours = false,
    required this.statusLabel,
    required this.displayMessage,
    this.safeRemainingSeconds,
  });

  factory MilkWarmingStatusModel.fromJson(Map<String, dynamic> json) {
    return MilkWarmingStatusModel(
      activeWarming: json['active_warming'] != null
          ? MilkWarmingRecordModel.fromJson(json['active_warming'])
          : null,
      activeDurationSeconds: json['active_duration_seconds'] is int
          ? json['active_duration_seconds']
          : int.tryParse(json['active_duration_seconds']?.toString() ?? ''),
      lastCompletedWarming: json['last_completed_warming'] != null
          ? MilkWarmingRecordModel.fromJson(json['last_completed_warming'])
          : null,
      secondsSinceLastWarming: json['seconds_since_last_warming'] is int
          ? json['seconds_since_last_warming']
          : int.tryParse(json['seconds_since_last_warming']?.toString() ?? ''),
      minutesSinceLastWarming: json['minutes_since_last_warming'] is int
          ? json['minutes_since_last_warming']
          : int.tryParse(json['minutes_since_last_warming']?.toString() ?? ''),
      isOver2Hours: json['is_over_2_hours'] == true,
      statusLabel: json['status_label']?.toString() ?? 'none',
      displayMessage: json['display_message']?.toString() ?? 'Chưa có cữ hâm',
      safeRemainingSeconds: json['safe_remaining_seconds'] is int
          ? json['safe_remaining_seconds']
          : int.tryParse(json['safe_remaining_seconds']?.toString() ?? ''),
    );
  }
}

class MilkWarmingDayGroupModel {
  final String dateStr;
  final String displayDate;
  final int totalAmountMl;
  final int sessionsCount;
  final List<MilkWarmingRecordModel> records;

  MilkWarmingDayGroupModel({
    required this.dateStr,
    required this.displayDate,
    required this.totalAmountMl,
    required this.sessionsCount,
    required this.records,
  });

  factory MilkWarmingDayGroupModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['records'] as List? ?? [];
    return MilkWarmingDayGroupModel(
      dateStr: json['date_str']?.toString() ?? '',
      displayDate: json['display_date']?.toString() ?? '',
      totalAmountMl: (json['total_amount_ml'] as num?)?.toInt() ?? 0,
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
      records: rawList.map((x) => MilkWarmingRecordModel.fromJson(x)).toList(),
    );
  }
}

class MilkWarmingOverviewModel {
  final MilkWarmingStatusModel status;
  final int todayTotalMl;
  final int todaySessionsCount;
  final List<MilkWarmingDayGroupModel> groups;

  MilkWarmingOverviewModel({
    required this.status,
    required this.todayTotalMl,
    required this.todaySessionsCount,
    required this.groups,
  });

  factory MilkWarmingOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List? ?? [];
    return MilkWarmingOverviewModel(
      status: MilkWarmingStatusModel.fromJson(json['status'] ?? {}),
      todayTotalMl: (json['today_total_ml'] as num?)?.toInt() ?? 0,
      todaySessionsCount: (json['today_sessions_count'] as num?)?.toInt() ?? 0,
      groups: rawGroups.map((x) => MilkWarmingDayGroupModel.fromJson(x)).toList(),
    );
  }
}
