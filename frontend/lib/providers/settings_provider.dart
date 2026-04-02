import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/services/storage_service.dart';
import '../core/network/api_base.dart';

class SettingsProvider extends ChangeNotifier {
  static const _farmLocationsStorageKeyPrefix = 'farm_locations_cache';
  static const _activeFarmStorageKeyPrefix = 'active_farm_id';
  static const _profileAvatarsStorageKey = 'profile_avatars_by_user';

  bool isLoading = false;
  String? error;
  Map<String, dynamic>? userProfile;
  List<dynamic>? farmLocations;
  String? _activeFarmId;
  Map<String, String> _profileAvatarsByUser = {};
  ThemeMode _themeMode = ThemeMode.system;

  SettingsProvider() {
    _loadThemeMode();
    _loadFarmLocationsFromStorage();
    _loadActiveFarmFromStorage();
    _loadProfileAvatarsFromStorage();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String? get activeFarmId => _activeFarmId;

  String get _apiBaseUrl => ApiBase.api;

  Map<String, dynamic>? get activeFarm {
    final activeId = _activeFarmId;
    if (activeId == null || activeId.isEmpty || farmLocations == null) return null;

    for (final item in farmLocations!) {
      if (item is Map && item['id']?.toString() == activeId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  String _farmLocationsStorageKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return _farmLocationsStorageKeyPrefix;
    }
    return '${_farmLocationsStorageKeyPrefix}_$uid';
  }

  String _activeFarmStorageKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return _activeFarmStorageKeyPrefix;
    }
    return '${_activeFarmStorageKeyPrefix}_$uid';
  }

  Future<void> _loadThemeMode() async {
    final storage = await StorageService.getInstance();
    final savedMode = storage.getThemeMode();

    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;

    final storage = await StorageService.getInstance();
    await storage.saveThemeMode(enabled ? 'dark' : 'light');

    notifyListeners();
  }

  Future<void> _loadFarmLocationsFromStorage() async {
    final storage = await StorageService.getInstance();
    final raw = storage.getString(_farmLocationsStorageKey());
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        farmLocations = decoded;
        notifyListeners();
      }
    } catch (_) {
      // Ignore malformed cache and keep runtime state.
    }
  }

  Future<void> _persistFarmLocations() async {
    final storage = await StorageService.getInstance();
    await storage.saveString(_farmLocationsStorageKey(), json.encode(farmLocations ?? []));
  }

  Future<void> _loadActiveFarmFromStorage() async {
    final storage = await StorageService.getInstance();
    _activeFarmId = storage.getString(_activeFarmStorageKey());
    notifyListeners();
  }

  Future<void> _persistActiveFarm() async {
    final storage = await StorageService.getInstance();
    if (_activeFarmId == null || _activeFarmId!.isEmpty) {
      await storage.remove(_activeFarmStorageKey());
      return;
    }

    await storage.saveString(_activeFarmStorageKey(), _activeFarmId!);
  }

  void _syncActiveFarmWithAvailableFarms() {
    final farms = (farmLocations ?? [])
        .whereType<Map>()
        .map((farm) => Map<String, dynamic>.from(farm))
        .where((farm) => (farm['id']?.toString() ?? '').isNotEmpty)
        .toList();

    if (farms.isEmpty) {
      _activeFarmId = null;
      return;
    }

    final activeId = _activeFarmId;
    if (activeId != null && farms.any((farm) => farm['id']?.toString() == activeId)) {
      return;
    }

    _activeFarmId = farms.first['id']?.toString();
  }

  Future<void> _loadProfileAvatarsFromStorage() async {
    final storage = await StorageService.getInstance();
    final raw = storage.getString(_profileAvatarsStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        _profileAvatarsByUser = decoded.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        )..removeWhere((_, value) => value.isEmpty);
        notifyListeners();
      }
    } catch (_) {
      // Ignore malformed cache and keep runtime state.
    }
  }

  Future<void> _persistProfileAvatars() async {
    final storage = await StorageService.getInstance();
    await storage.saveString(_profileAvatarsStorageKey, json.encode(_profileAvatarsByUser));
  }

  String? getProfileAvatarForUser(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    final value = _profileAvatarsByUser[userId];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setProfileAvatarForUser({required String userId, required String base64Image}) async {
    if (userId.isEmpty) return;

    final cleaned = base64Image.trim();
    if (cleaned.isEmpty) return;

    _profileAvatarsByUser[userId] = cleaned;
    await _persistProfileAvatars();
    notifyListeners();
  }

  Future<void> selectActiveFarm(String? farmId) async {
    final id = farmId?.trim();
    if (id == null || id.isEmpty) {
      _activeFarmId = null;
      await _persistActiveFarm();
      notifyListeners();
      return;
    }

    final farms = farmLocations ?? [];
    final exists = farms.any((farm) => farm is Map && farm['id']?.toString() == id);
    if (!exists) {
      error = 'Selected farm is not in your farm list';
      notifyListeners();
      return;
    }

    _activeFarmId = id;
    await _persistActiveFarm();
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        return;
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/auth/firebase/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        userProfile = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : decoded;
      } else {
        error = 'Failed to load profile';
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFarmLocations() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final previousFarms = farmLocations == null ? null : List<dynamic>.from(farmLocations!);
    final previousActiveFarmId = _activeFarmId;

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        farmLocations = previousFarms;
        _activeFarmId = previousActiveFarmId;
        return;
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/farms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        farmLocations = data['data'];
        _syncActiveFarmWithAvailableFarms();
        await _persistFarmLocations();
        await _persistActiveFarm();
      } else {
        try {
          final responseBody = json.decode(response.body);
          final backendError = responseBody is Map<String, dynamic> ? responseBody['error']?.toString() : null;
          error = backendError?.isNotEmpty == true ? backendError : 'Failed to load farm locations';
        } catch (_) {
          error = 'Failed to load farm locations';
        }

        // Keep existing farms on request failure so users are not forced into false onboarding.
        farmLocations = previousFarms;
        _activeFarmId = previousActiveFarmId;
      }
    } catch (e) {
      error = e.toString();
      farmLocations = previousFarms;
      _activeFarmId = previousActiveFarmId;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createFarm({required String name, String? location, double? size}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      error = 'Farm name is required';
      notifyListeners();
      return false;
    }

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/farms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': trimmedName,
          'location': location?.trim().isNotEmpty == true ? location!.trim() : null,
          'size': size,
        }),
      );

      if (response.statusCode == 201) {
        await fetchFarmLocations();
        return true;
      }

      try {
        final responseBody = json.decode(response.body);
        final backendError = responseBody is Map<String, dynamic> ? responseBody['error']?.toString() : null;
        error = backendError?.isNotEmpty == true ? backendError : 'Failed to create farm';
      } catch (_) {
        error = 'Failed to create farm';
      }
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateFarmLocation({required String farmId, required String location}) async {
    final trimmedLocation = location.trim();
    if (trimmedLocation.isEmpty) return;

    final current = List<dynamic>.from(farmLocations ?? []);

    if (current.isEmpty) {
      current.add({
        'id': farmId,
        'name': 'Main Farm',
        'location': trimmedLocation,
      });
    } else {
      final index = current.indexWhere((farm) {
        if (farm is Map) {
          return farm['id']?.toString() == farmId;
        }
        return false;
      });

      final targetIndex = index >= 0 ? index : 0;
      final rawFarm = current[targetIndex];
      final farmMap = rawFarm is Map ? Map<String, dynamic>.from(rawFarm) : <String, dynamic>{};

      farmMap['id'] = farmMap['id']?.toString() ?? farmId;
      farmMap['name'] = farmMap['name']?.toString() ?? 'Main Farm';
      farmMap['location'] = trimmedLocation;
      current[targetIndex] = farmMap;
    }

    farmLocations = current;
    _syncActiveFarmWithAvailableFarms();
    await _persistFarmLocations();
    await _persistActiveFarm();
    notifyListeners();
  }
}
