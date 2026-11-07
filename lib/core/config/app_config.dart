import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String keyBaseUrl = 'app_config_base_url';

  // Default points to localhost:8000 via adb reverse tcp:8000 tcp:8000
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api';
  static const String lanBaseUrl = 'http://192.168.1.132:8000/api';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      _currentBaseUrl = saved.trim();
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _currentBaseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, _currentBaseUrl);
  }
}
