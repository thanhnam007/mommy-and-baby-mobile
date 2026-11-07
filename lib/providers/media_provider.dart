import 'dart:io';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/media_model.dart';

class MediaProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<MediaModel> _mediaList = [];
  bool _isLoading = false;
  bool _isUploading = false;

  List<MediaModel> get mediaList => _mediaList;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  Future<void> fetchMedia(int babyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getMediaList(babyId: babyId, limit: 50);
      if (res.statusCode == 200) {
        final list = (res.data is Map ? res.data['items'] : res.data) as List? ?? [];
        _mediaList = list.map((item) => MediaModel.fromJson(item)).toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> uploadMedia(File file, int babyId, {int? activityId, String? caption}) async {
    _isUploading = true;
    notifyListeners();

    try {
      final res = await _api.uploadMedia(file, babyId, activityId: activityId, caption: caption);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchMedia(babyId);
        _isUploading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isUploading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteMedia(int id, int babyId) async {
    try {
      final res = await _api.deleteMedia(id);
      if (res.statusCode == 200) {
        await fetchMedia(babyId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
