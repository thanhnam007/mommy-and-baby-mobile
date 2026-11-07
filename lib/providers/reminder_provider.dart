import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/reminder_model.dart';

class ReminderProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<ReminderModel> _reminders = [];
  bool _isLoading = false;

  List<ReminderModel> get reminders => _reminders;
  bool get isLoading => _isLoading;

  Future<void> fetchReminders({int? babyId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getReminders(babyId: babyId);
      if (res.statusCode == 200) {
        final list = (res.data is Map ? res.data['items'] : res.data) as List? ?? [];
        _reminders = list.map((item) => ReminderModel.fromJson(item)).toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReminder(Map<String, dynamic> data, {int? babyId}) async {
    try {
      final res = await _api.createReminder(data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchReminders(babyId: babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateReminder(int id, Map<String, dynamic> data, {int? babyId}) async {
    try {
      final res = await _api.updateReminder(id, data);
      if (res.statusCode == 200) {
        await fetchReminders(babyId: babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> toggleReminder(int id, {int? babyId}) async {
    try {
      final res = await _api.toggleReminder(id);
      if (res.statusCode == 200) {
        await fetchReminders(babyId: babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteReminder(int id, {int? babyId}) async {
    try {
      final res = await _api.deleteReminder(id);
      if (res.statusCode == 200) {
        await fetchReminders(babyId: babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> testSend(int id) async {
    try {
      final res = await _api.testSendReminder(id);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
