import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Generic methods
  Future<void> saveString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  String? getString(String key) {
    return _preferences?.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  Future<void> saveInt(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  Future<void> saveDouble(String key, double value) async {
    await _preferences?.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }

  Future<void> saveStringList(String key, List<String> value) async {
    await _preferences?.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _preferences?.getStringList(key);
  }

  // JSON methods
  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await saveString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Remove and clear methods
  Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }

  Future<void> clear() async {
    await _preferences?.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _preferences?.containsKey(key) ?? false;
  }

  // Authentication specific methods
  Future<void> saveAuthToken(String token) async {
    await saveString(AppConstants.authTokenKey, token);
  }

  String? getAuthToken() {
    return getString(AppConstants.authTokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await saveJson(AppConstants.userDataKey, userData);
  }

  Map<String, dynamic>? getUserData() {
    return getJson(AppConstants.userDataKey);
  }

  Future<void> saveRememberMe(bool remember) async {
    await saveBool(AppConstants.rememberMeKey, remember);
  }

  bool? getRememberMe() {
    return getBool(AppConstants.rememberMeKey);
  }

  Future<void> clearAuthData() async {
    await remove(AppConstants.authTokenKey);
    await remove(AppConstants.userDataKey);
  }

  // Cache methods
  Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? expiration}) async {
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiration': expiration?.inMilliseconds,
    };
    await saveJson('cache_$key', cacheEntry);
  }

  Map<String, dynamic>? getCachedData(String key) {
    final cacheEntry = getJson('cache_$key');
    if (cacheEntry == null) return null;

    final timestamp = cacheEntry['timestamp'] as int?;
    final expiration = cacheEntry['expiration'] as int?;

    if (timestamp == null) return null;

    if (expiration != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - timestamp > expiration) {
        remove('cache_$key');
        return null;
      }
    }

    return cacheEntry['data'] as Map<String, dynamic>?;
  }

  Future<void> clearCache() async {
    final keys = _preferences?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await remove(key);
      }
    }
  }

  // Settings methods
  Future<void> saveThemeMode(String themeMode) async {
    await saveString('theme_mode', themeMode);
  }

  String? getThemeMode() {
    return getString('theme_mode');
  }

  Future<void> saveLanguage(String languageCode) async {
    await saveString('language', languageCode);
  }

  String? getLanguage() {
    return getString('language');
  }

  Future<void> saveFirstLaunch(bool isFirstLaunch) async {
    await saveBool('first_launch', isFirstLaunch);
  }

  bool? isFirstLaunch() {
    return getBool('first_launch');
  }

  // Debug method to print all stored keys
  void printAllKeys() {
    final keys = _preferences?.getKeys() ?? {};
    for (final key in keys) {
      final value = _preferences?.get(key);
      print('Storage: $key = $value');
    }
  }
}
