import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/pumping_model.dart';

class PumpingProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  PumpingOverviewModel? _overview;
  PumpingTodaySummaryModel? _todaySummary;
  bool _isLoading = false;
  String _rangeType = 'day';
  String? _customStartDate;
  String? _customEndDate;

  PumpingOverviewModel? get overview => _overview;
  PumpingTodaySummaryModel? get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  String get rangeType => _rangeType;
  String? get customStartDate => _customStartDate;
  String? get customEndDate => _customEndDate;

  void setRangeType(String type, int? babyId) {
    _rangeType = type;
    fetchOverview(babyId);
  }

  void setCustomRange(String start, String end, int? babyId) {
    _customStartDate = start;
    _customEndDate = end;
    _rangeType = 'custom';
    fetchOverview(babyId);
  }

  Future<void> fetchOverview(int? babyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getPumpingOverview(
        babyId: babyId,
        rangeType: _rangeType,
        startDate: _rangeType == 'custom' ? _customStartDate : null,
        endDate: _rangeType == 'custom' ? _customEndDate : null,
      );
      if (res.statusCode == 200) {
        _overview = PumpingOverviewModel.fromJson(res.data);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTodaySummary() async {
    try {
      final res = await _api.getPumpingSummaryToday();
      if (res.statusCode == 200) {
        _todaySummary = PumpingTodaySummaryModel.fromJson(res.data);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createRecord({
    int? babyId,
    required DateTime startTime,
    required DateTime endTime,
    required int amountMl,
    String breastSide = 'both',
    int? leftAmountMl,
    int? rightAmountMl,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'amount_ml': amountMl,
        'breast_side': breastSide,
      };
      if (babyId != null) data['baby_id'] = babyId;
      if (leftAmountMl != null) data['left_amount_ml'] = leftAmountMl;
      if (rightAmountMl != null) data['right_amount_ml'] = rightAmountMl;
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;

      final res = await _api.createPumpingRecord(data);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await Future.wait([fetchOverview(babyId), fetchTodaySummary()]);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateRecord(
    int recordId, {
    int? babyId,
    required DateTime startTime,
    required DateTime endTime,
    required int amountMl,
    String breastSide = 'both',
    int? leftAmountMl,
    int? rightAmountMl,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'amount_ml': amountMl,
        'breast_side': breastSide,
        'left_amount_ml': leftAmountMl,
        'right_amount_ml': rightAmountMl,
        'notes': notes,
      };
      if (babyId != null) data['baby_id'] = babyId;

      final res = await _api.updatePumpingRecord(recordId, data);

      if (res.statusCode == 200) {
        await Future.wait([fetchOverview(babyId), fetchTodaySummary()]);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteRecord(int recordId, int? babyId) async {
    try {
      final res = await _api.deletePumpingRecord(recordId);
      if (res.statusCode == 200) {
        await Future.wait([fetchOverview(babyId), fetchTodaySummary()]);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
