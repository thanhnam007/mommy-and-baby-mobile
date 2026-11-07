class PumpingRecordModel {
  final int id;
  final int userId;
  final int? babyId;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final int amountMl;
  final String breastSide;
  final int? leftAmountMl;
  final int? rightAmountMl;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  PumpingRecordModel({
    required this.id,
    required this.userId,
    this.babyId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.amountMl,
    required this.breastSide,
    this.leftAmountMl,
    this.rightAmountMl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PumpingRecordModel.fromJson(Map<String, dynamic> json) {
    return PumpingRecordModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      babyId: json['baby_id'] is int ? json['baby_id'] : int.tryParse(json['baby_id']?.toString() ?? ''),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      durationMinutes: json['duration_minutes'] is int ? json['duration_minutes'] : int.tryParse(json['duration_minutes'].toString()) ?? 0,
      amountMl: json['amount_ml'] is int ? json['amount_ml'] : int.tryParse(json['amount_ml'].toString()) ?? 0,
      breastSide: json['breast_side']?.toString() ?? 'both',
      leftAmountMl: json['left_amount_ml'] != null ? (json['left_amount_ml'] as num).toInt() : null,
      rightAmountMl: json['right_amount_ml'] != null ? (json['right_amount_ml'] as num).toInt() : null,
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class PumpingChartPointModel {
  final String label;
  final String timestamp;
  final int amountMl;
  final int sessionCount;

  PumpingChartPointModel({
    required this.label,
    required this.timestamp,
    required this.amountMl,
    this.sessionCount = 1,
  });

  factory PumpingChartPointModel.fromJson(Map<String, dynamic> json) {
    return PumpingChartPointModel(
      label: json['label']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      amountMl: (json['amount_ml'] as num?)?.toInt() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 1,
    );
  }
}

class PumpingDayGroupModel {
  final String dateStr;
  final String displayDate;
  final int totalAmountMl;
  final int totalDurationMinutes;
  final int sessionsCount;
  final List<PumpingRecordModel> records;

  PumpingDayGroupModel({
    required this.dateStr,
    required this.displayDate,
    required this.totalAmountMl,
    required this.totalDurationMinutes,
    required this.sessionsCount,
    required this.records,
  });

  factory PumpingDayGroupModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['records'] as List? ?? [];
    return PumpingDayGroupModel(
      dateStr: json['date_str']?.toString() ?? '',
      displayDate: json['display_date']?.toString() ?? '',
      totalAmountMl: (json['total_amount_ml'] as num?)?.toInt() ?? 0,
      totalDurationMinutes: (json['total_duration_minutes'] as num?)?.toInt() ?? 0,
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
      records: rawList.map((x) => PumpingRecordModel.fromJson(x)).toList(),
    );
  }
}

class PumpingSummaryStatsModel {
  final int totalAmountMl;
  final int totalSessions;
  final double avgPerSessionMl;
  final double avgPerDayMl;
  final String? lastPumpingTime;
  final int? minutesSinceLastPumping;
  final int? comparePrevPeriodDiffMl;

  PumpingSummaryStatsModel({
    required this.totalAmountMl,
    required this.totalSessions,
    required this.avgPerSessionMl,
    required this.avgPerDayMl,
    this.lastPumpingTime,
    this.minutesSinceLastPumping,
    this.comparePrevPeriodDiffMl,
  });

  factory PumpingSummaryStatsModel.fromJson(Map<String, dynamic> json) {
    return PumpingSummaryStatsModel(
      totalAmountMl: (json['total_amount_ml'] as num?)?.toInt() ?? 0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      avgPerSessionMl: (json['avg_per_session_ml'] as num?)?.toDouble() ?? 0.0,
      avgPerDayMl: (json['avg_per_day_ml'] as num?)?.toDouble() ?? 0.0,
      lastPumpingTime: json['last_pumping_time']?.toString(),
      minutesSinceLastPumping: json['minutes_since_last_pumping'] != null
          ? (json['minutes_since_last_pumping'] as num).toInt()
          : null,
      comparePrevPeriodDiffMl: json['compare_prev_period_diff_ml'] != null
          ? (json['compare_prev_period_diff_ml'] as num).toInt()
          : null,
    );
  }
}

class PumpingOverviewModel {
  final String rangeType;
  final String? startDate;
  final String? endDate;
  final PumpingSummaryStatsModel stats;
  final List<PumpingChartPointModel> chartPoints;
  final double averageMl;
  final List<PumpingDayGroupModel> groups;

  PumpingOverviewModel({
    required this.rangeType,
    this.startDate,
    this.endDate,
    required this.stats,
    required this.chartPoints,
    required this.averageMl,
    required this.groups,
  });

  factory PumpingOverviewModel.fromJson(Map<String, dynamic> json) {
    var rawPts = json['chart_points'] as List? ?? [];
    var rawGroups = json['groups'] as List? ?? [];
    return PumpingOverviewModel(
      rangeType: json['range_type']?.toString() ?? 'day',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      stats: PumpingSummaryStatsModel.fromJson(json['stats'] ?? {}),
      chartPoints: rawPts.map((x) => PumpingChartPointModel.fromJson(x)).toList(),
      averageMl: (json['average_ml'] as num?)?.toDouble() ?? 0.0,
      groups: rawGroups.map((x) => PumpingDayGroupModel.fromJson(x)).toList(),
    );
  }
}

class PumpingTodaySummaryModel {
  final int todayTotalMl;
  final int todaySessionsCount;
  final String? lastPumpingTime;
  final int? minutesSinceLastPumping;

  PumpingTodaySummaryModel({
    required this.todayTotalMl,
    required this.todaySessionsCount,
    this.lastPumpingTime,
    this.minutesSinceLastPumping,
  });

  factory PumpingTodaySummaryModel.fromJson(Map<String, dynamic> json) {
    return PumpingTodaySummaryModel(
      todayTotalMl: (json['today_total_ml'] as num?)?.toInt() ?? 0,
      todaySessionsCount: (json['today_sessions_count'] as num?)?.toInt() ?? 0,
      lastPumpingTime: json['last_pumping_time']?.toString(),
      minutesSinceLastPumping: json['minutes_since_last_pumping'] != null
          ? (json['minutes_since_last_pumping'] as num).toInt()
          : null,
    );
  }
}
