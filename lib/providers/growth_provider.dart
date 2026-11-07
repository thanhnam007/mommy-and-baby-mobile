import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/growth_model.dart';

class GrowthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  GrowthSummaryModel? _summary;
  bool _isLoading = false;
  String _rangeType = 'all';

  GrowthSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String get rangeType => _rangeType;

  void setRangeType(String type, int babyId) {
    _rangeType = type;
    fetchGrowth(babyId);
  }

  Future<void> fetchGrowth(int babyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getGrowthSummary(babyId, rangeType: _rangeType);
      if (res.statusCode == 200) {
        _summary = GrowthSummaryModel.fromJson(res.data);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addRecord(int babyId, double? weight, double? height, {DateTime? date, String? notes}) async {
    try {
      final d = date ?? DateTime.now();
      final res = await _api.createGrowthRecord({
        'baby_id': babyId,
        'recorded_at': d.toUtc().toIso8601String(),
        if (weight != null) 'weight_kg': weight,
        if (height != null) 'height_cm': height,
        if (notes != null) 'notes': notes,
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchGrowth(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateRecord(int recordId, int babyId, double? weight, double? height, {DateTime? date, String? notes}) async {
    try {
      final res = await _api.updateGrowthRecord(recordId, {
        if (date != null) 'recorded_at': date.toUtc().toIso8601String(),
        'weight_kg': weight,
        'height_cm': height,
        if (notes != null) 'notes': notes,
      });

      if (res.statusCode == 200) {
        await fetchGrowth(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteRecord(int recordId, int babyId) async {
    try {
      final res = await _api.deleteGrowthRecord(recordId);
      if (res.statusCode == 200) {
        await fetchGrowth(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
