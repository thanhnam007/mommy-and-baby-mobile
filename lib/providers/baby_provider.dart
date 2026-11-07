import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/baby_model.dart';

class BabyProvider extends ChangeNotifier {
  static const String keyActiveBabyId = 'active_baby_id';
  final ApiClient _api = ApiClient();

  List<BabyModel> _babies = [];
  BabyModel? _activeBaby;
  bool _isLoading = false;

  List<BabyModel> get babies => _babies;
  BabyModel? get activeBaby => _activeBaby;
  bool get isLoading => _isLoading;

  Future<void> fetchBabies() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getBabies();
      if (res.statusCode == 200) {
        final list = res.data as List? ?? [];
        _babies = list.map((item) => BabyModel.fromJson(item)).toList();

        final prefs = await SharedPreferences.getInstance();
        final savedId = prefs.getInt(keyActiveBabyId);

        if (_babies.isNotEmpty) {
          if (savedId != null) {
            final match = _babies.where((b) => b.id == savedId);
            _activeBaby = match.isNotEmpty ? match.first : _babies.first;
          } else {
            _activeBaby = _babies.first;
          }
        } else {
          _activeBaby = null;
        }
      }
    } catch (_) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectBaby(BabyModel baby) async {
    _activeBaby = baby;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyActiveBabyId, baby.id);
  }

  Future<bool> createBaby(Map<String, dynamic> data) async {
    try {
      final res = await _api.createBaby(data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchBabies();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateBaby(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.updateBaby(id, data);
      if (res.statusCode == 200) {
        await fetchBabies();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteBaby(int id) async {
    try {
      final res = await _api.deleteBaby(id);
      if (res.statusCode == 200) {
        await fetchBabies();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
