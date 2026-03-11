import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SettingsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? userProfile;
  List<dynamic>? farmLocations;

  Future<void> fetchProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('https://atahbracha.com/api/auth/me'));
      if (response.statusCode == 200) {
        userProfile = json.decode(response.body);
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
    try {
      final response = await http.get(Uri.parse('https://atahbracha.com/api/farms'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        farmLocations = data['data'];
      } else {
        error = 'Failed to load farm locations';
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
