import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  Dio get dio => _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String keyToken = 'jwt_auth_token';
  String? _token;

  Function()? onUnauthorized;

  // Active requests counter for global loading indicator
  final ValueNotifier<int> activeRequestsNotifier = ValueNotifier<int>(0);
  int _activeRequestsCount = 0;

  // In-flight mutations tracking to prevent duplicate concurrent requests
  final Set<String> _inFlightMutations = <String>{};

  void _incrementActiveRequests() {
    _activeRequestsCount++;
    activeRequestsNotifier.value = _activeRequestsCount;
  }

  void _decrementActiveRequests() {
    if (_activeRequestsCount > 0) {
      _activeRequestsCount--;
      activeRequestsNotifier.value = _activeRequestsCount;
    }
  }

  ApiClient._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final method = options.method.toUpperCase();
          final isMutating = ['POST', 'PUT', 'DELETE', 'PATCH'].contains(method);

          if (isMutating) {
            String payloadStr = '';
            try {
              if (options.data != null) {
                payloadStr = options.data is Map || options.data is List
                    ? jsonEncode(options.data)
                    : options.data.toString();
              }
            } catch (_) {
              payloadStr = options.data?.toString() ?? '';
            }

            final mutationKey = '$method:${options.path}:$payloadStr';
            if (_inFlightMutations.contains(mutationKey)) {
              if (kDebugMode) {
                print('[ApiClient] Duplicate in-flight mutating request suppressed: $mutationKey');
              }
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  error: 'Thao tác đang được xử lý, vui lòng không gửi yêu cầu lặp lại.',
                ),
              );
            }

            _inFlightMutations.add(mutationKey);
            options.extra['_inFlightKey'] = mutationKey;
          }

          _incrementActiveRequests();

          _token ??= await _storage.read(key: keyToken);
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _decrementActiveRequests();
          final key = response.requestOptions.extra['_inFlightKey'] as String?;
          if (key != null) {
            _inFlightMutations.remove(key);
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          _decrementActiveRequests();
          final key = error.requestOptions.extra['_inFlightKey'] as String?;
          if (key != null) {
            _inFlightMutations.remove(key);
          }

          final path = error.requestOptions.path;
          if (error.response?.statusCode == 401 && !path.contains('/auth/login')) {
            await clearToken();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl() {
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: keyToken, value: token);
  }

  Future<String?> getToken() async {
    _token ??= await _storage.read(key: keyToken);
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: keyToken);
  }

  // ----------------- Auth -----------------
  Future<Response> login(String username, String password) async {
    updateBaseUrl();
    return _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> register(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/auth/register', data: data);
  }

  Future<Response> getMe() async {
    updateBaseUrl();
    return _dio.get('/auth/me');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/auth/profile', data: data);
  }

  // ----------------- Babies -----------------
  Future<Response> getBabies() async {
    updateBaseUrl();
    return _dio.get('/babies');
  }

  Future<Response> createBaby(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/babies', data: data);
  }

  Future<Response> updateBaby(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/babies/$id', data: data);
  }

  Future<Response> deleteBaby(int id) async {
    updateBaseUrl();
    return _dio.delete('/babies/$id');
  }

  // ----------------- Activities -----------------
  Future<Response> getFeedingSummary(int babyId, {String? targetDate}) async {
    updateBaseUrl();
    final tz = DateTime.now().timeZoneOffset.inMinutes;
    String url = '/activities/feeding/daily-summary?baby_id=$babyId&tz_offset=$tz';
    if (targetDate != null) url += '&target_date=$targetDate';
    return _dio.get(url);
  }

  Future<Response> getSleepSummary(int babyId, {String? targetDate}) async {
    updateBaseUrl();
    final tz = DateTime.now().timeZoneOffset.inMinutes;
    String url = '/activities/sleeping/daily-summary?baby_id=$babyId&tz_offset=$tz';
    if (targetDate != null) url += '&target_date=$targetDate';
    return _dio.get(url);
  }

  Future<Response> getTimeline(int babyId, {String? targetDate, String? type}) async {
    updateBaseUrl();
    final tz = DateTime.now().timeZoneOffset.inMinutes;
    String url = '/activities/timeline?baby_id=$babyId&tz_offset=$tz';
    if (targetDate != null) url += '&target_date=$targetDate';
    if (type != null && type.isNotEmpty && type != 'all') url += '&activity_type=$type';
    return _dio.get(url);
  }

  Future<Response> logFeeding(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/feeding', data: data);
  }

  Future<Response> startFeeding(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/feeding/start', data: data);
  }

  Future<Response> endFeeding(int activityId, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/feeding/$activityId/end', data: data);
  }

  Future<Response> startSleep(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/sleeping/start', data: data);
  }

  Future<Response> endSleep(int activityId, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/sleeping/$activityId/end', data: data);
  }

  Future<Response> manualSleep(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/sleeping/manual', data: data);
  }

  Future<Response> logDiaper(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/diaper', data: data);
  }

  Future<Response> logBath(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/bath', data: data);
  }

  Future<Response> logPlay(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/play', data: data);
  }

  Future<Response> logSolid(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/activities/solid', data: data);
  }

  Future<Response> deleteActivity(int id) async {
    updateBaseUrl();
    return _dio.delete('/activities/$id');
  }

  Future<Response> updateActivity(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/activities/$id', data: data);
  }

  // ----------------- Growth -----------------
  Future<Response> getGrowthSummary(int babyId, {String rangeType = 'all', String? startDate, String? endDate}) async {
    updateBaseUrl();
    final tz = DateTime.now().timeZoneOffset.inMinutes;
    String url = '/growth?baby_id=$babyId&range_type=$rangeType&tz_offset=$tz';
    if (rangeType == 'custom') {
      if (startDate != null) url += '&start_date=$startDate';
      if (endDate != null) url += '&end_date=$endDate';
    }
    return _dio.get(url);
  }

  Future<Response> createGrowthRecord(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/growth', data: data);
  }

  Future<Response> updateGrowthRecord(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/growth/$id', data: data);
  }

  Future<Response> deleteGrowthRecord(int id) async {
    updateBaseUrl();
    return _dio.delete('/growth/$id');
  }

  Future<Response> getWhoStandards({String gender = 'boy', int maxMonths = 60}) async {
    updateBaseUrl();
    return _dio.get('/growth/who-standards?gender=$gender&max_months=$maxMonths');
  }

  // ----------------- Camera -----------------
  Future<Response> getCameras({int? babyId}) async {
    updateBaseUrl();
    String url = '/cameras';
    if (babyId != null) url += '?baby_id=$babyId';
    return _dio.get(url);
  }

  Future<Response> controlCameraPTZ(int cameraId, String direction, {int durationMs = 500}) async {
    updateBaseUrl();
    return _dio.post('/cameras/$cameraId/ptz', data: {
      'direction': direction,
      'duration_ms': durationMs,
    });
  }

  Future<Response> refreshCameraSnapshot(int cameraId) async {
    updateBaseUrl();
    return _dio.post('/cameras/$cameraId/snapshot');
  }

  Future<Response> connectImou(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/cameras/imou/connect', data: data);
  }

  Future<Response> syncImou({int? babyId}) async {
    updateBaseUrl();
    String url = '/cameras/imou/sync';
    if (babyId != null) url += '?baby_id=$babyId';
    return _dio.post(url);
  }

  Future<Response> disconnectImou() async {
    updateBaseUrl();
    return _dio.delete('/cameras/imou/disconnect');
  }

  Future<Response> seedDemoCameras({int? babyId}) async {
    updateBaseUrl();
    String url = '/cameras/demo-seed';
    if (babyId != null) url += '?baby_id=$babyId';
    return _dio.post(url);
  }

  Future<Response> createManualCamera(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/cameras/manual', data: data);
  }

  Future<Response> updateCamera(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/cameras/$id', data: data);
  }

  Future<Response> deleteCamera(int id) async {
    updateBaseUrl();
    return _dio.delete('/cameras/$id');
  }

  Future<Response> refreshCameraStream(int id) async {
    updateBaseUrl();
    return _dio.get('/cameras/$id/stream');
  }

  // ----------------- Reminders -----------------
  Future<Response> getReminders({int? babyId}) async {
    updateBaseUrl();
    String url = '/reminders';
    if (babyId != null) url += '?baby_id=$babyId';
    return _dio.get(url);
  }

  Future<Response> createReminder(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/reminders', data: data);
  }

  Future<Response> updateReminder(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/reminders/$id', data: data);
  }

  Future<Response> toggleReminder(int id) async {
    updateBaseUrl();
    return _dio.post('/reminders/$id/toggle');
  }

  Future<Response> testSendReminder(int id) async {
    updateBaseUrl();
    return _dio.post('/reminders/$id/test-send');
  }

  Future<Response> deleteReminder(int id) async {
    updateBaseUrl();
    return _dio.delete('/reminders/$id');
  }

  // ----------------- Media -----------------
  Future<Response> getMediaList({int? babyId, int? activityId, int limit = 50, int offset = 0}) async {
    updateBaseUrl();
    String url = '/media?limit=$limit&offset=$offset';
    if (babyId != null) url += '&baby_id=$babyId';
    if (activityId != null) url += '&activity_id=$activityId';
    return _dio.get(url);
  }

  Future<Response> uploadMedia(File file, int babyId, {int? activityId, String? caption}) async {
    updateBaseUrl();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'baby_id': babyId,
      if (activityId != null) 'activity_id': activityId,
      if (caption != null) 'caption': caption,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    return _dio.post('/media/upload', data: formData);
  }

  Future<Response> deleteMedia(int id) async {
    updateBaseUrl();
    return _dio.delete('/media/$id');
  }

  // ----------------- Pumping (Hút sữa mẹ) -----------------
  Future<Response> getPumpingOverview({
    int? babyId,
    String rangeType = 'day',
    String? startDate,
    String? endDate,
    int tzOffset = 420,
  }) async {
    updateBaseUrl();
    String url = '/pumping?range_type=$rangeType&tz_offset=$tzOffset';
    if (babyId != null) url += '&baby_id=$babyId';
    if (startDate != null && startDate.isNotEmpty) url += '&start_date=$startDate';
    if (endDate != null && endDate.isNotEmpty) url += '&end_date=$endDate';
    return _dio.get(url);
  }

  Future<Response> getPumpingSummaryToday({int tzOffset = 420}) async {
    updateBaseUrl();
    return _dio.get('/pumping/summary-today?tz_offset=$tzOffset');
  }

  Future<Response> createPumpingRecord(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/pumping', data: data);
  }

  Future<Response> updatePumpingRecord(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/pumping/$id', data: data);
  }

  Future<Response> deletePumpingRecord(int id) async {
    updateBaseUrl();
    return _dio.delete('/pumping/$id');
  }

  // ----------------- Milk Warming (Lịch hâm sữa) -----------------
  Future<Response> getMilkWarmingStatus({int? babyId}) async {
    updateBaseUrl();
    String url = '/milk-warming/status';
    if (babyId != null) url += '?baby_id=$babyId';
    return _dio.get(url);
  }

  Future<Response> getMilkWarmingOverview({
    int? babyId,
    String? startDate,
    String? endDate,
    int tzOffset = 420,
  }) async {
    updateBaseUrl();
    String url = '/milk-warming?tz_offset=$tzOffset';
    if (babyId != null) url += '&baby_id=$babyId';
    if (startDate != null && startDate.isNotEmpty) url += '&start_date=$startDate';
    if (endDate != null && endDate.isNotEmpty) url += '&end_date=$endDate';
    return _dio.get(url);
  }

  Future<Response> quickStartMilkWarming(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/milk-warming/quick-start', data: data);
  }

  Future<Response> endMilkWarming(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/milk-warming/$id/end', data: data);
  }

  Future<Response> cancelMilkWarming(int id) async {
    updateBaseUrl();
    return _dio.post('/milk-warming/$id/cancel');
  }

  Future<Response> createManualMilkWarming(Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.post('/milk-warming/manual', data: data);
  }

  Future<Response> updateMilkWarming(int id, Map<String, dynamic> data) async {
    updateBaseUrl();
    return _dio.put('/milk-warming/$id', data: data);
  }

  Future<Response> deleteMilkWarming(int id) async {
    updateBaseUrl();
    return _dio.delete('/milk-warming/$id');
  }
}
