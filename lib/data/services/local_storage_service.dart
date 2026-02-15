import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';

/// Local storage service using SharedPreferences
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;
  final Logger _logger = Logger();
  
  LocalStorageService._();
  
  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  // API Configuration
  Future<void> setApiUrl(String url) async {
    await _preferences?.setString(AppConstants.keyApiUrl, url);
    _logger.d('API URL saved: $url');
  }
  
  String? getApiUrl() {
    return _preferences?.getString(AppConstants.keyApiUrl);
  }
  
  Future<void> setApiKey(String key) async {
    await _preferences?.setString(AppConstants.keyApiKey, key);
    _logger.d('API key saved');
  }
  
  String? getApiKey() {
    return _preferences?.getString(AppConstants.keyApiKey);
  }
  
  // Theme
  Future<void> setThemeMode(String mode) async {
    await _preferences?.setString(AppConstants.keyThemeMode, mode);
  }
  
  String getThemeMode() {
    return _preferences?.getString(AppConstants.keyThemeMode) ?? 'system';
  }
  
  // Auto Refresh
  Future<void> setAutoRefresh(bool enabled) async {
    await _preferences?.setBool(AppConstants.keyAutoRefresh, enabled);
  }
  
  bool getAutoRefresh() {
    return _preferences?.getBool(AppConstants.keyAutoRefresh) ?? true;
  }
  
  Future<void> setRefreshInterval(int seconds) async {
    await _preferences?.setInt(AppConstants.keyRefreshInterval, seconds);
  }
  
  int getRefreshInterval() {
    return _preferences?.getInt(AppConstants.keyRefreshInterval) ?? 30;
  }
  
  // Generic methods
  Future<void> setString(String key, String value) async {
    await _preferences?.setString(key, value);
  }
  
  String? getString(String key) {
    return _preferences?.getString(key);
  }
  
  Future<void> setBool(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }
  
  bool? getBool(String key) {
    return _preferences?.getBool(key);
  }
  
  Future<void> setInt(String key, int value) async {
    await _preferences?.setInt(key, value);
  }
  
  int? getInt(String key) {
    return _preferences?.getInt(key);
  }
  
  Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }
  
  Future<void> clear() async {
    await _preferences?.clear();
    _logger.w('All local storage cleared');
  }
  
  /// Check if API is configured
  bool get isApiConfigured {
    final url = getApiUrl();
    final key = getApiKey();
    return url != null && url.isNotEmpty && key != null && key.isNotEmpty;
  }
}
