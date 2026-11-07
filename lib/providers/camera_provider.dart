import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/camera_model.dart';

class CameraProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<CameraModel> _cameras = [];
  CameraModel? _selectedCamera;
  bool _isLoading = false;
  bool _isSyncing = false;

  bool _imouConnected = false;
  String? _appId;
  String? _appIdMasked;
  String? _appSecretMasked;
  String _apiBaseUrl = 'https://openapi.easy4ip.com';
  DateTime? _lastSyncedAt;
  String _viewMode = 'focus'; // 'focus' or 'grid'

  List<CameraModel> get cameras => _cameras;
  CameraModel? get selectedCamera => _selectedCamera;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get imouConnected => _imouConnected;
  String? get appId => _appId;
  String? get appIdMasked => _appIdMasked;
  String? get appSecretMasked => _appSecretMasked;
  String get apiBaseUrl => _apiBaseUrl;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String get viewMode => _viewMode;

  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void selectCamera(CameraModel camera) {
    _selectedCamera = camera;
    notifyListeners();
  }

  void selectCameraById(int id) {
    try {
      _selectedCamera = _cameras.firstWhere((c) => c.id == id);
      notifyListeners();
    } catch (_) {}
  }

  void _parseResponseData(dynamic data) {
    if (data is Map) {
      _imouConnected = data['imou_connected'] == true;
      _appId = data['app_id']?.toString();
      _appIdMasked = data['app_id_masked']?.toString();
      _appSecretMasked = data['app_secret_masked']?.toString();
      _apiBaseUrl = data['api_base_url']?.toString() ?? 'https://openapi.easy4ip.com';
      if (data['last_synced_at'] != null) {
        _lastSyncedAt = DateTime.tryParse(data['last_synced_at'].toString());
      }

      final rawList = data['cameras'] as List? ?? data['items'] as List? ?? [];
      _cameras = rawList.map((item) => CameraModel.fromJson(item as Map<String, dynamic>)).toList();
    } else if (data is List) {
      _cameras = data.map((item) => CameraModel.fromJson(item as Map<String, dynamic>)).toList();
    }

    if (_cameras.isNotEmpty) {
      if (_selectedCamera != null) {
        final existingIdx = _cameras.indexWhere((c) => c.id == _selectedCamera!.id);
        _selectedCamera = existingIdx >= 0 ? _cameras[existingIdx] : _cameras.first;
      } else {
        _selectedCamera = _cameras.first;
      }
    } else {
      _selectedCamera = null;
    }
  }

  Future<void> fetchCameras({int? babyId, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await _api.getCameras(babyId: babyId);
      if (res.statusCode == 200 && res.data != null) {
        _parseResponseData(res.data);
      }
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
    }

    if (!silent) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connectImou({
    required String appId,
    String? appSecret,
    String? apiBaseUrl,
    int? babyId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'app_id': appId.trim(),
        'app_secret': appSecret?.trim(),
        'api_base_url': (apiBaseUrl != null && apiBaseUrl.trim().isNotEmpty)
            ? apiBaseUrl.trim()
            : 'https://openapi.easy4ip.com',
        if (babyId != null) 'baby_id': babyId,
      };

      final res = await _api.connectImou(payload);
      if (res.statusCode == 200 && res.data != null) {
        _parseResponseData(res.data);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error connecting Imou: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> syncImou({int? babyId}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final res = await _api.syncImou(babyId: babyId);
      if (res.statusCode == 200 && res.data != null) {
        _parseResponseData(res.data);
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error syncing Imou: $e');
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  Future<bool> disconnectImou() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.disconnectImou();
      if (res.statusCode == 200) {
        _imouConnected = false;
        _appId = null;
        _appIdMasked = null;
        _appSecretMasked = null;
        _cameras.removeWhere((c) => c.sourceType == 'imou' || c.sourceType == 'imou_cloud');
        if (_selectedCamera != null && !_cameras.any((c) => c.id == _selectedCamera!.id)) {
          _selectedCamera = _cameras.isNotEmpty ? _cameras.first : null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error disconnecting Imou: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> seedDemoCameras({int? babyId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.seedDemoCameras(babyId: babyId);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data != null) {
          _parseResponseData(res.data);
        } else {
          await fetchCameras(babyId: babyId, silent: true);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error seeding demo cameras: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> createManualCamera(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.createManualCamera(data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchCameras(silent: true);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error creating manual camera: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateCamera(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.updateCamera(id, data);
      if (res.statusCode == 200 && res.data != null) {
        final updated = CameraModel.fromJson(res.data);
        final idx = _cameras.indexWhere((c) => c.id == id);
        if (idx >= 0) {
          _cameras[idx] = updated;
          if (_selectedCamera?.id == id) {
            _selectedCamera = updated;
          }
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating camera: $e');
    }
    return false;
  }

  Future<bool> deleteCamera(int id) async {
    try {
      final res = await _api.deleteCamera(id);
      if (res.statusCode == 200) {
        _cameras.removeWhere((c) => c.id == id);
        if (_selectedCamera?.id == id) {
          _selectedCamera = _cameras.isNotEmpty ? _cameras.first : null;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting camera: $e');
    }
    return false;
  }

  Future<bool> controlPTZ(String direction, {int? cameraId, int durationMs = 500}) async {
    final targetId = cameraId ?? _selectedCamera?.id;
    if (targetId == null) return false;

    try {
      final res = await _api.controlCameraPTZ(targetId, direction, durationMs: durationMs);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error PTZ: $e');
      return false;
    }
  }

  Future<void> refreshSnapshot({int? cameraId}) async {
    final targetId = cameraId ?? _selectedCamera?.id;
    if (targetId == null) return;

    try {
      final res = await _api.refreshCameraSnapshot(targetId);
      if (res.statusCode == 200 && res.data != null) {
        final updated = CameraModel.fromJson(res.data);
        final idx = _cameras.indexWhere((c) => c.id == targetId);
        if (idx >= 0) {
          _cameras[idx] = updated;
          if (_selectedCamera?.id == targetId) {
            _selectedCamera = updated;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing snapshot: $e');
    }
  }

  Future<void> refreshCameraStream({int? cameraId}) async {
    final targetId = cameraId ?? _selectedCamera?.id;
    if (targetId == null) return;

    try {
      final res = await _api.refreshCameraStream(targetId);
      if (res.statusCode == 200 && res.data != null) {
        final updated = CameraModel.fromJson(res.data);
        final idx = _cameras.indexWhere((c) => c.id == targetId);
        if (idx >= 0) {
          _cameras[idx] = updated;
          if (_selectedCamera?.id == targetId) {
            _selectedCamera = updated;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing camera stream: $e');
    }
  }
}
