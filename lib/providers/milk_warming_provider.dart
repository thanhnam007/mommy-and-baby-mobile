import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/milk_warming_model.dart';

class MilkWarmingProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  MilkWarmingStatusModel? _status;
  MilkWarmingOverviewModel? _overview;
  bool _isLoading = false;
  bool _isActionLoading = false;
  Timer? _timer;

  MilkWarmingStatusModel? get status => _status;
  MilkWarmingOverviewModel? get overview => _overview;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;

  MilkWarmingProvider() {
    // 1-second real-time timer for accurate second-by-second updates
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != null) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get isWarming => _status?.activeWarming != null;

  int get liveActiveDurationSeconds {
    final start = _status?.activeWarming?.startDateTime;
    if (start == null) return 0;
    final diff = DateTime.now().toUtc().difference(start.toUtc()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  int? get liveSecondsSinceLastWarming {
    final end = _status?.lastCompletedWarming?.endDateTime;
    if (end == null) return null;
    final diff = DateTime.now().toUtc().difference(end.toUtc()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  bool get isAllWarmedMilkConsumed {
    if (isWarming) return false;
    if (_status?.isAllConsumed == true) return true;
    final corr = _overview?.todayCorrelation;
    if (corr != null && corr.warmedTotalMl > 0 && corr.consumedWarmedMl >= corr.warmedTotalMl) {
      return true;
    }
    return false;
  }

  // 2 hours = 7200 seconds rule
  bool get liveIsOver2Hours {
    if (isWarming) return false;
    if (isAllWarmedMilkConsumed) return false;
    final sec = liveSecondsSinceLastWarming;
    if (sec == null) return false;
    return sec > 7200;
  }

  int? get liveSafeRemainingSeconds {
    final sec = liveSecondsSinceLastWarming;
    if (sec == null) return null;
    final rem = 7200 - sec;
    return rem < 0 ? 0 : rem;
  }

  Future<void> fetchStatus(int? babyId) async {
    try {
      final res = await _api.getMilkWarmingStatus(babyId: babyId);
      if (res.statusCode == 200 && res.data != null) {
        _status = MilkWarmingStatusModel.fromJson(res.data);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchOverview(int? babyId, {String? startDate, String? endDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getMilkWarmingOverview(
        babyId: babyId,
        startDate: startDate,
        endDate: endDate,
      );
      if (res.statusCode == 200 && res.data != null) {
        _overview = MilkWarmingOverviewModel.fromJson(res.data);
        _status = _overview!.status;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> quickStart({int? babyId, required int amountMl, String? notes}) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {
        'amount_ml': amountMl,
      };
      if (babyId != null) data['baby_id'] = babyId;
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;

      final res = await _api.quickStartMilkWarming(data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await Future.wait([fetchStatus(babyId), fetchOverview(babyId)]);
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isActionLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> endWarming(int recordId, {int? babyId, int? amountMl, String? notes}) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (amountMl != null) data['amount_ml'] = amountMl;
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;

      final res = await _api.endMilkWarming(recordId, data);
      if (res.statusCode == 200) {
        await Future.wait([fetchStatus(babyId), fetchOverview(babyId)]);
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isActionLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> cancelWarming(int recordId, int? babyId) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final res = await _api.cancelMilkWarming(recordId);
      if (res.statusCode == 200) {
        await Future.wait([fetchStatus(babyId), fetchOverview(babyId)]);
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isActionLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> createManual({
    int? babyId,
    required DateTime startTime,
    required DateTime endTime,
    required int amountMl,
    String? notes,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'amount_ml': amountMl,
      };
      if (babyId != null) data['baby_id'] = babyId;
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;

      final res = await _api.createManualMilkWarming(data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await Future.wait([fetchStatus(babyId), fetchOverview(babyId)]);
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isActionLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateRecord(
    int recordId, {
    int? babyId,
    DateTime? startTime,
    DateTime? endTime,
    int? amountMl,
    String? notes,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (startTime != null) data['start_time'] = startTime.toUtc().toIso8601String();
      if (endTime != null) data['end_time'] = endTime.toUtc().toIso8601String();
      if (amountMl != null) data['amount_ml'] = amountMl;
      if (notes != null) data['notes'] = notes;
      if (babyId != null) data['baby_id'] = babyId;

      final res = await _api.updateMilkWarming(recordId, data);
      if (res.statusCode == 200) {
        await Future.wait([fetchStatus(babyId), fetchOverview(babyId)]);
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isActionLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteRecord(int recordId, int? babyId) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final res = await _api.deleteMilkWarming(recordId);
      if (res.statusCode == 200 || res.statusCode == 204) {
        await Future.wait([fetchStatus(babyId), fetchOverview(babyId)]);
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isActionLoading = false;
    notifyListeners();
    return false;
  }

  static String formatSecondsToDigital(int totalSec) {
    final s = totalSec % 60;
    final totalMins = totalSec ~/ 60;
    final m = totalMins % 60;
    final h = totalMins ~/ 60;
    final sPad = s.toString().padLeft(2, '0');
    final mPad = m.toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$mPad:$sPad';
    }
    return '$mPad:$sPad';
  }

  static String formatSecondsToDurationText(int totalSec) {
    final s = totalSec % 60;
    final totalMins = totalSec ~/ 60;
    final m = totalMins % 60;
    final h = totalMins ~/ 60;
    if (h > 0) return '${h}g ${m}p ${s}s';
    if (m > 0) return '${m}p ${s}s';
    return '${s}s';
  }

  static String formatElapsedAgo(DateTime? dt) {
    if (dt == null) return 'Chưa có';
    final sec = DateTime.now().toUtc().difference(dt.toUtc()).inSeconds;
    if (sec < 0) return 'Vừa xong';
    final s = sec % 60;
    final totalMins = sec ~/ 60;
    final m = totalMins % 60;
    final h = totalMins ~/ 60;
    if (h >= 24) {
      final days = h ~/ 24;
      return '$days ngày trước';
    }
    if (h > 0) return '${h}g ${m}p ${s}s trước';
    if (m > 0) return '${m}p ${s}s trước';
    return '${s}s trước';
  }
}
