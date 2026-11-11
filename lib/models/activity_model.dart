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
  final String? lastFeedingEnd;
  final int? minutesSinceLastFeeding;
  final int? currentFeedingDurationMinutes;
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
    this.lastFeedingEnd,
    this.minutesSinceLastFeeding,
    this.currentFeedingDurationMinutes,
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

  String formatElapsedHero([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (isCurrentlyFeeding && currentFeedingStart != null) {
      try {
        final start = DateTime.parse(currentFeedingStart!).toLocal();
        final diffSec = current.difference(start).inSeconds;
        final dur = _formatLiveDuration(diffSec);
        final t = _formatTimeOnly(start);
        return '$dur (từ $t)';
      } catch (_) {}
    }
    if (lastFeedingTime != null) {
      try {
        final start = DateTime.parse(lastFeedingTime!).toLocal();
        final diffSec = current.difference(start).inSeconds;
        final ago = _formatLiveElapsedAgo(diffSec);
        final t = _formatTimeOnly(start);
        return '$ago ($t)';
      } catch (_) {}
    }
    return 'Chưa có cữ bú';
  }

  String formatElapsedCard([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (isCurrentlyFeeding && currentFeedingStart != null) {
      try {
        final start = DateTime.parse(currentFeedingStart!).toLocal();
        final diffSec = current.difference(start).inSeconds;
        return _formatLiveDuration(diffSec);
      } catch (_) {}
    }
    if (lastFeedingTime != null) {
      try {
        final start = DateTime.parse(lastFeedingTime!).toLocal();
        final diffSec = current.difference(start).inSeconds;
        return _formatLiveElapsedAgo(diffSec);
      } catch (_) {}
    }
    return 'Chưa có';
  }

  factory FeedingSummaryModel.fromJson(Map<String, dynamic> json) {
    return FeedingSummaryModel(
      totalMl: json['total_ml'] ?? 0,
      totalNursingMinutes: json['total_nursing_minutes'] ?? 0,
      feedingCount: json['feeding_count'] ?? 0,
      lastFeedingTime: json['last_feeding_time'],
      lastFeedingEnd: json['last_feeding_end'],
      minutesSinceLastFeeding: json['minutes_since_last_feeding'],
      currentFeedingDurationMinutes: json['current_feeding_duration_minutes'],
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
  final int? currentSleepDurationMinutes;
  final String? lastSleepStart;
  final String? lastSleepEnd;
  final int? minutesSinceLastSleep;

  SleepSummaryModel({
    required this.totalSleepMinutes,
    required this.totalSleepFormatted,
    required this.sleepCount,
    required this.isCurrentlySleeping,
    this.currentSleepId,
    this.currentSleepStart,
    this.currentSleepDurationMinutes,
    this.lastSleepStart,
    this.lastSleepEnd,
    this.minutesSinceLastSleep,
  });

  String formatElapsedHero([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (isCurrentlySleeping && currentSleepStart != null) {
      try {
        final start = DateTime.parse(currentSleepStart!).toLocal();
        final diffSec = current.difference(start).inSeconds;
        final dur = _formatLiveDuration(diffSec);
        final t = _formatTimeOnly(start);
        return '$dur (từ $t)';
      } catch (_) {}
    }
    if (lastSleepEnd != null) {
      try {
        final end = DateTime.parse(lastSleepEnd!).toLocal();
        final diffSec = current.difference(end).inSeconds;
        final dur = _formatLiveDuration(diffSec);
        final t = _formatTimeOnly(end);
        return '$dur (dậy $t)';
      } catch (_) {}
    }
    return 'Bé đang thức';
  }

  String formatElapsedCard([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (isCurrentlySleeping && currentSleepStart != null) {
      try {
        final start = DateTime.parse(currentSleepStart!).toLocal();
        final diffSec = current.difference(start).inSeconds;
        return _formatLiveDuration(diffSec);
      } catch (_) {}
    }
    if (lastSleepEnd != null) {
      try {
        final end = DateTime.parse(lastSleepEnd!).toLocal();
        final diffSec = current.difference(end).inSeconds;
        return _formatLiveDuration(diffSec);
      } catch (_) {}
    }
    return 'Chưa có';
  }

  factory SleepSummaryModel.fromJson(Map<String, dynamic> json) {
    return SleepSummaryModel(
      totalSleepMinutes: json['total_sleep_minutes'] ?? 0,
      totalSleepFormatted: json['total_sleep_formatted'] ?? '0g 0p',
      sleepCount: json['sleep_count'] ?? 0,
      isCurrentlySleeping: json['is_currently_sleeping'] == true,
      currentSleepId: json['current_sleep_id'],
      currentSleepStart: json['current_sleep_start'],
      currentSleepDurationMinutes: json['current_sleep_duration_minutes'],
      lastSleepStart: json['last_sleep_start'],
      lastSleepEnd: json['last_sleep_end'],
      minutesSinceLastSleep: json['minutes_since_last_sleep'],
    );
  }
}

String _formatLiveDuration(int totalSeconds) {
  final sec = totalSeconds >= 0 ? totalSeconds : 0;
  if (sec < 60) return '$sec s';
  final m = (sec ~/ 60) % 60;
  final h = sec ~/ 3600;
  final s = sec % 60;
  if (h > 0) return '${h}g ${m}p ${s}s';
  return '${m}p ${s}s';
}

String _formatLiveElapsedAgo(int totalSeconds) {
  final sec = totalSeconds >= 0 ? totalSeconds : 0;
  if (sec < 60) return '$sec s trước';
  final totalMins = sec ~/ 60;
  final m = totalMins % 60;
  final h = totalMins ~/ 60;
  final s = sec % 60;
  if (h >= 24) {
    return '${h ~/ 24} ngày trước';
  }
  if (h > 0) return '${h}g ${m}p ${s}s trước';
  return '${m}p ${s}s trước';
}

String _formatDurationMinutes(int mins) {
  if (mins < 60) return '$mins phút';
  final h = mins ~/ 60;
  final m = mins % 60;
  return m > 0 ? '${h}g ${m}p' : '$h giờ';
}

String _formatElapsedAgo(int mins) {
  if (mins < 1) return 'Vừa xong';
  if (mins < 60) return '$mins phút trước';
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h >= 24) {
    return '${h ~/ 24} ngày trước';
  }
  return m > 0 ? '${h}g ${m}p trước' : '$h giờ trước';
}

String _formatTimeOnly(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
