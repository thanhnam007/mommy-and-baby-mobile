class ActivityModel {
  final int id;
  final int babyId;
  final String activityType; // feeding, sleeping, diaper, bath, play, solid, other
  final String startTime;
  final String? endTime;
  final int? durationMinutes;
  final String? feedingType; // breast, bottle_breast, formula, solid
  final int? amountMl;
  final String? breastSide; // left, right, both
  final int? nursingMinutes;
  final String? sleepQuality; // good, normal, restless
  final String? diaperType; // pee, poop, both, dry
  final String? notes;
  final String createdAt;

  ActivityModel({
    required this.id,
    required this.babyId,
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.feedingType,
    this.amountMl,
    this.breastSide,
    this.nursingMinutes,
    this.sleepQuality,
    this.diaperType,
    this.notes,
    required this.createdAt,
  });

  String get icon {
    switch (activityType) {
      case 'feeding':
        return feedingType == 'breast' ? '🤱' : '🍼';
      case 'sleeping':
        return '😴';
      case 'diaper':
        return '🧷';
      case 'bath':
        return '🛁';
      case 'play':
        return '🎈';
      case 'solid':
        return '🥣';
      default:
        return '📝';
    }
  }

  String get title {
    switch (activityType) {
      case 'feeding':
        if (feedingType == 'breast') {
          return 'Bú mẹ direct ${breastSide != null ? "($breastSide)" : ""}';
        }
        return 'Bú bình ${amountMl != null ? "$amountMl ml" : ""}';
      case 'sleeping':
        return durationMinutes != null ? 'Giấc ngủ ($durationMinutes phút)' : 'Giấc ngủ';
      case 'diaper':
        final type = diaperType == 'pee' ? 'Tè' : diaperType == 'poop' ? 'Ị' : diaperType == 'both' ? 'Tè + Ị' : 'Tã sạch';
        return 'Thay tã ($type)';
      case 'bath':
        return 'Tắm bé';
      case 'play':
        return 'Vận động / Tummy time';
      case 'solid':
        return amountMl != null ? 'Bữa ăn dặm ($amountMl g)' : 'Bữa ăn dặm';
      default:
        return 'Hoạt động';
    }
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      babyId: json['baby_id'] is int ? json['baby_id'] : int.tryParse(json['baby_id'].toString()) ?? 0,
      activityType: json['activity_type'] ?? 'other',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'],
      feedingType: json['feeding_type'],
      amountMl: json['amount_ml'],
      breastSide: json['breast_side'],
      nursingMinutes: json['nursing_minutes'],
      sleepQuality: json['sleep_quality'],
      diaperType: json['diaper_type'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class FeedingSummaryModel {
  final int totalMl;
  final int totalNursingMinutes;
  final int feedingCount;
  final String? lastFeedingTime;
  final bool isCurrentlyFeeding;
  final int? currentFeedingId;
  final String? currentFeedingStart;

  // Phân tách cữ bú mẹ riêng & bú bình riêng (sữa CT & bình sữa mẹ)
  final int breastCount;
  final int breastNursingMinutes;
  final int bottleCount;
  final int bottleTotalMl;
  final int formulaCount;
  final int formulaMl;
  final int bottleBreastCount;
  final int bottleBreastMl;

  FeedingSummaryModel({
    required this.totalMl,
    required this.totalNursingMinutes,
    required this.feedingCount,
    this.lastFeedingTime,
    required this.isCurrentlyFeeding,
    this.currentFeedingId,
    this.currentFeedingStart,
    this.breastCount = 0,
    this.breastNursingMinutes = 0,
    this.bottleCount = 0,
    this.bottleTotalMl = 0,
    this.formulaCount = 0,
    this.formulaMl = 0,
    this.bottleBreastCount = 0,
    this.bottleBreastMl = 0,
  });

  factory FeedingSummaryModel.fromJson(Map<String, dynamic> json) {
    return FeedingSummaryModel(
      totalMl: json['total_ml'] ?? 0,
      totalNursingMinutes: json['total_nursing_minutes'] ?? 0,
      feedingCount: json['feeding_count'] ?? 0,
      lastFeedingTime: json['last_feeding_time'],
      isCurrentlyFeeding: json['is_currently_feeding'] == true,
      currentFeedingId: json['current_feeding_id'],
      currentFeedingStart: json['current_feeding_start'],
      breastCount: json['breast_count'] ?? 0,
      breastNursingMinutes: json['breast_nursing_minutes'] ?? 0,
      bottleCount: json['bottle_count'] ?? 0,
      bottleTotalMl: json['bottle_total_ml'] ?? 0,
      formulaCount: json['formula_count'] ?? 0,
      formulaMl: json['formula_ml'] ?? 0,
      bottleBreastCount: json['bottle_breast_count'] ?? 0,
      bottleBreastMl: json['bottle_breast_ml'] ?? 0,
    );
  }
}

class SleepSummaryModel {
  final int totalSleepMinutes;
  final String totalSleepFormatted;
  final int sleepCount;
  final bool isCurrentlySleeping;
  final int? currentSleepId;
  final String? currentSleepStart;

  SleepSummaryModel({
    required this.totalSleepMinutes,
    required this.totalSleepFormatted,
    required this.sleepCount,
    required this.isCurrentlySleeping,
    this.currentSleepId,
    this.currentSleepStart,
  });

  factory SleepSummaryModel.fromJson(Map<String, dynamic> json) {
    return SleepSummaryModel(
      totalSleepMinutes: json['total_sleep_minutes'] ?? 0,
      totalSleepFormatted: json['total_sleep_formatted'] ?? '0g 0p',
      sleepCount: json['sleep_count'] ?? 0,
      isCurrentlySleeping: json['is_currently_sleeping'] == true,
      currentSleepId: json['current_sleep_id'],
      currentSleepStart: json['current_sleep_start'],
    );
  }
}
