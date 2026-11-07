import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _api.onUnauthorized = () {
      _user = null;
      notifyListeners();
    };
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();
      final res = await _api.getMe();
      if (res.statusCode == 200) {
        _user = UserModel.fromJson(res.data);
      }
    } catch (_) {
      await _api.clearToken();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(dynamic e, String defaultMessage) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) {
          return detail;
        } else if (detail is List) {
          return detail.map((item) {
            if (item is Map && item['msg'] != null) {
              return item['msg'].toString();
            }
            return item.toString();
          }).join(', ');
        }
        return detail.toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        return 'Không thể kết nối đến máy chủ (quá thời gian chờ). Vui lòng thử lại!';
      } else if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra địa chỉ máy chủ!';
      }
    }
    return defaultMessage;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.login(username, password);
      if (res.statusCode == 200) {
        final token = res.data['access_token'];
        await _api.saveToken(token);
        if (res.data['user'] != null) {
          _user = UserModel.fromJson(res.data['user']);
        } else {
          final meRes = await _api.getMe();
          _user = UserModel.fromJson(meRes.data);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(
        e,
        'Đăng nhập không thành công. Vui lòng kiểm tra lại tài khoản!',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> register(String username, String password, {String? fullName, String? email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.register({
        'username': username,
        'password': password,
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return await login(username, password);
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(
        e,
        'Đăng ký thất bại. Tên đăng nhập có thể đã tồn tại.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }
}
