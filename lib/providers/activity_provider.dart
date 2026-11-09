import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';

class ActivityProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  FeedingSummaryModel? _feedingSummary;
  SleepSummaryModel? _sleepSummary;
  List<ActivityModel> _allTimeline = [];
  bool _isLoading = false;
  bool _isFeedingActionLoading = false;
  bool _isSleepActionLoading = false;
  String _selectedType = 'all';
  String? _currentTargetDate;

  FeedingSummaryModel? get feedingSummary => _feedingSummary;
  SleepSummaryModel? get sleepSummary => _sleepSummary;
  List<ActivityModel> get allTimeline => _allTimeline;
  List<ActivityModel> get timeline {
    if (_selectedType == 'all') return _allTimeline;
    if (_selectedType == 'other') {
      return _allTimeline
          .where((a) => a.activityType == 'bath' || a.activityType == 'play' || a.activityType == 'other')
          .toList();
    }
    return _allTimeline.where((a) => a.activityType == _selectedType).toList();
  }

  Map<String, int> get categoryCounts {
    int feeding = 0;
    int solid = 0;
    int sleeping = 0;
    int diaper = 0;
    int other = 0;
    for (final a in _allTimeline) {
      switch (a.activityType) {
        case 'feeding':
          feeding++;
          break;
        case 'solid':
          solid++;
          break;
        case 'sleeping':
          sleeping++;
          break;
        case 'diaper':
          diaper++;
          break;
        case 'bath':
        case 'play':
        default:
          other++;
          break;
      }
    }
    return {
      'all': _allTimeline.length,
      'feeding': feeding,
      'solid': solid,
      'sleeping': sleeping,
      'diaper': diaper,
      'other': other,
    };
  }

  bool get isLoading => _isLoading;
  bool get isFeedingActionLoading => _isFeedingActionLoading;
  bool get isSleepActionLoading => _isSleepActionLoading;
  String get selectedType => _selectedType;

  bool get isSleeping => _sleepSummary?.isCurrentlySleeping ?? false;
  bool get isFeeding => _feedingSummary?.isCurrentlyFeeding ?? false;

  void setFilterType(String type, int babyId) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  @visibleForTesting
  void setTimelineForTesting(List<ActivityModel> items) {
    _allTimeline = List<ActivityModel>.from(items);
    notifyListeners();
  }

  @visibleForTesting
  void setSummariesForTesting({
    FeedingSummaryModel? feedingSummary,
    SleepSummaryModel? sleepSummary,
    bool? isFeedingActionLoading,
    bool? isSleepActionLoading,
  }) {
    if (feedingSummary != null) _feedingSummary = feedingSummary;
    if (sleepSummary != null) _sleepSummary = sleepSummary;
    if (isFeedingActionLoading != null) _isFeedingActionLoading = isFeedingActionLoading;
    if (isSleepActionLoading != null) _isSleepActionLoading = isSleepActionLoading;
    notifyListeners();
  }

  Future<void> fetchAll(int babyId) async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      fetchSummaries(babyId),
      fetchTimeline(babyId, targetDate: _currentTargetDate),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSummaries(int babyId) async {
    try {
      final results = await Future.wait([
        _api.getFeedingSummary(babyId),
        _api.getSleepSummary(babyId),
      ]);

      if (results[0].statusCode == 200) {
        _feedingSummary = FeedingSummaryModel.fromJson(results[0].data);
      }
      if (results[1].statusCode == 200) {
        _sleepSummary = SleepSummaryModel.fromJson(results[1].data);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTimeline(int babyId, {String? targetDate}) async {
    if (targetDate != null) {
      _currentTargetDate = targetDate;
    }
    try {
      final res = await _api.getTimeline(babyId, targetDate: _currentTargetDate, type: 'all');
      if (res.statusCode == 200) {
        final list = res.data as List? ?? [];
        _allTimeline = list.map((item) => ActivityModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // --- Sleep actions ---
  Future<bool> startSleep(int babyId, {DateTime? startTime, String? sleepQuality, String? notes}) async {
    if (_isSleepActionLoading) return false;
    _isSleepActionLoading = true;
    notifyListeners();
    try {
      final t = startTime ?? DateTime.now();
      final res = await _api.startSleep({
        'baby_id': babyId,
        'start_time': t.toUtc().toIso8601String(),
        if (sleepQuality != null) 'sleep_quality': sleepQuality,
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {
    } finally {
      _isSleepActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateSleep(
    int babyId,
    int activityId, {
    required DateTime startTime,
    DateTime? endTime,
    String sleepQuality = 'good',
    String? notes,
  }) async {
    try {
      final res = await _api.updateActivity(activityId, {
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime?.toUtc().toIso8601String(),
        if (endTime == null) 'duration_minutes': null,
        'sleep_quality': sleepQuality,
        'notes': notes,
      });
      if (res.statusCode == 200) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> endSleep(int babyId, int activityId, {DateTime? endTime, String? sleepQuality, String? notes}) async {
    if (_isSleepActionLoading) return false;
    _isSleepActionLoading = true;
    notifyListeners();
    try {
      final t = endTime ?? DateTime.now();
      final res = await _api.endSleep(activityId, {
        'end_time': t.toUtc().toIso8601String(),
        'sleep_quality': sleepQuality ?? 'good',
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {
    } finally {
      _isSleepActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> manualSleep(int babyId, DateTime start, DateTime? end, {String sleepQuality = 'good', String? notes}) async {
    try {
      final res = await _api.manualSleep({
        'baby_id': babyId,
        'start_time': start.toUtc().toIso8601String(),
        if (end != null) 'end_time': end.toUtc().toIso8601String(),
        'sleep_quality': sleepQuality,
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- Feeding actions ---
  Future<bool> logBottleFeeding(int babyId, int amountMl, {String feedingType = 'formula', DateTime? time, String? notes}) async {
    try {
      final t = time ?? DateTime.now();
      final res = await _api.logFeeding({
        'baby_id': babyId,
        'feeding_type': feedingType,
        'amount_ml': amountMl,
        'start_time': t.toUtc().toIso8601String(),
        'end_time': t.add(const Duration(minutes: 15)).toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> startBreastFeeding(int babyId, String side, {DateTime? startTime, String? notes}) async {
    if (_isFeedingActionLoading) return false;
    _isFeedingActionLoading = true;
    notifyListeners();
    try {
      final t = startTime ?? DateTime.now();
      final res = await _api.startFeeding({
        'baby_id': babyId,
        'feeding_type': 'breast',
        'breast_side': side,
        'start_time': t.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {
    } finally {
      _isFeedingActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> endBreastFeeding(int babyId, int activityId, int minutes, {DateTime? endTime, String? side, String? notes}) async {
    if (_isFeedingActionLoading) return false;
    _isFeedingActionLoading = true;
    notifyListeners();
    try {
      final t = endTime ?? DateTime.now();
      final res = await _api.endFeeding(activityId, {
        'end_time': t.toUtc().toIso8601String(),
        'feeding_type': 'breast',
        'nursing_minutes': minutes,
        if (side != null) 'breast_side': side,
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {
    } finally {
      _isFeedingActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> manualBreastFeeding(int babyId, DateTime start, DateTime? end, {String side = 'left', int? minutes, String? notes}) async {
    try {
      final res = await _api.logFeeding({
        'baby_id': babyId,
        'feeding_type': 'breast',
        'breast_side': side,
        'start_time': start.toUtc().toIso8601String(),
        if (end != null) 'end_time': end.toUtc().toIso8601String(),
        if (minutes != null) 'nursing_minutes': minutes,
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- Diaper actions ---
  Future<bool> logDiaper(int babyId, String diaperType, {DateTime? time, String? notes}) async {
    try {
      final t = time ?? DateTime.now();
      final res = await _api.logDiaper({
        'baby_id': babyId,
        'diaper_type': diaperType,
        'start_time': t.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- Other activities ---
  Future<bool> logBath(int babyId, {DateTime? time, String? notes}) async {
    try {
      final t = time ?? DateTime.now();
      final res = await _api.logBath({
        'baby_id': babyId,
        'start_time': t.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> logSolid(int babyId, int amountMl, {DateTime? time, String? notes}) async {
    try {
      final t = time ?? DateTime.now();
      final res = await _api.logSolid({
        'baby_id': babyId,
        'amount_ml': amountMl,
        'start_time': t.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> logPlay(int babyId, int minutes, {DateTime? time, String? notes}) async {
    try {
      final t = time ?? DateTime.now();
      final res = await _api.logPlay({
        'baby_id': babyId,
        'start_time': t.toUtc().toIso8601String(),
        'end_time': t.add(Duration(minutes: minutes)).toUtc().toIso8601String(),
        'duration_minutes': minutes,
        if (notes != null) 'notes': notes,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteActivity(int activityId, int babyId) async {
    try {
      final res = await _api.deleteActivity(activityId);
      if (res.statusCode == 200) {
        await fetchAll(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
