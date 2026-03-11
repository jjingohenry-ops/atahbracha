import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DashboardProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? stats;
  Map<String, dynamic>? aiInsights;
  List<dynamic>? alerts;
  List<dynamic>? recentActivity;

  Future<void> fetchDashboardData() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('https://atahbracha.com/api/dashboard'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        stats = data['stats'];
        aiInsights = data['aiInsights'];
        alerts = data['alerts'];
        recentActivity = data['recentActivity'];
      } else {
        error = 'Failed to load dashboard data';
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
