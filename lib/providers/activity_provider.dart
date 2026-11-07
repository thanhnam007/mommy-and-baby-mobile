import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';

class ActivityProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  FeedingSummaryModel? _feedingSummary;
  SleepSummaryModel? _sleepSummary;
  List<ActivityModel> _timeline = [];
  bool _isLoading = false;
  String _selectedType = 'all';

  FeedingSummaryModel? get feedingSummary => _feedingSummary;
  SleepSummaryModel? get sleepSummary => _sleepSummary;
  List<ActivityModel> get timeline => _timeline;
  bool get isLoading => _isLoading;
  String get selectedType => _selectedType;

  bool get isSleeping => _sleepSummary?.isCurrentlySleeping ?? false;
  bool get isFeeding => _feedingSummary?.isCurrentlyFeeding ?? false;

  void setFilterType(String type, int babyId) {
    _selectedType = type;
    fetchTimeline(babyId);
  }

  Future<void> fetchAll(int babyId) async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      fetchSummaries(babyId),
      fetchTimeline(babyId),
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
    try {
      final res = await _api.getTimeline(babyId, targetDate: targetDate, type: _selectedType);
      if (res.statusCode == 200) {
        final list = res.data as List? ?? [];
        _timeline = list.map((item) => ActivityModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // --- Sleep actions ---
  Future<bool> startSleep(int babyId, {DateTime? startTime, String? notes}) async {
    try {
      final t = startTime ?? DateTime.now();
      final res = await _api.startSleep({
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

  Future<bool> endSleep(int babyId, int activityId, {DateTime? endTime, String? sleepQuality, String? notes}) async {
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
    } catch (_) {}
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
    } catch (_) {}
    return false;
  }

  Future<bool> endBreastFeeding(int babyId, int activityId, int minutes, {DateTime? endTime, String? side, String? notes}) async {
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
    } catch (_) {}
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
