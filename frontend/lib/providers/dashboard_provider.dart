import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_base.dart';

class DashboardProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isSavingAction = false;
  String? error;
  String? actionError;
  String? actionSuccess;
  Map<String, dynamic>? stats;
  Map<String, dynamic>? aiInsights;
  List<dynamic>? alerts;
  List<dynamic>? recentActivity;
  Map<String, dynamic>? trends;
  List<dynamic>? animalSnapshot;

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final dynamic body = json.decode(response.body);
      final dynamic message =
          body['error'] ?? body['message'] ?? body['details']?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Ignore parse failures and return fallback.
    }
    return fallback;
  }

  Future<String?> _getAuthToken() async {
    final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> fetchDashboardData({String? farmId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        isLoading = false;
        notifyListeners();
        return;
      }

      final uri = ApiBase.uri(
        '/dashboard',
        queryParameters: farmId != null && farmId.isNotEmpty ? {'farmId': farmId} : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        stats = data['stats'];
        aiInsights = data['aiInsights'];
        alerts = data['alerts'];
        recentActivity = data['recentActivity'];
        trends = data['trends'];
        animalSnapshot = data['animalSnapshot'];
      } else {
        error = 'Failed to load dashboard data (${response.statusCode})';
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> _postAction(
    String path,
    Map<String, dynamic> payload,
    String successMessage,
  ) async {
    isSavingAction = true;
    actionError = null;
    actionSuccess = null;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        actionError = 'Authentication required';
        return false;
      }

      final http.Response response = await http.post(
        ApiBase.uri(path),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        actionSuccess = successMessage;
        return true;
      }

      actionError = _extractErrorMessage(response, 'Failed to save action');
      return false;
    } catch (e) {
      actionError = e.toString();
      return false;
    } finally {
      isSavingAction = false;
      notifyListeners();
    }
  }

  Future<bool> recordTreatment({
    required String farmId,
    required String animalId,
    required String drugName,
    required String dosage,
    required DateTime date,
    String? notes,
  }) async {
    return _postAction(
      '/dashboard/actions/treatment',
      <String, dynamic>{
        'farmId': farmId,
        'animalId': animalId,
        'drugName': drugName,
        'dosage': dosage,
        'date': date.toIso8601String(),
        'notes': notes,
      },
      'Treatment recorded successfully',
    );
  }

  Future<bool> logFeeding({
    required String farmId,
    required String animalId,
    required String foodType,
    required double quantity,
    required DateTime time,
    String? notes,
  }) async {
    return _postAction(
      '/dashboard/actions/feeding',
      <String, dynamic>{
        'farmId': farmId,
        'animalId': animalId,
        'foodType': foodType,
        'quantity': quantity,
        'time': time.toIso8601String(),
        'notes': notes,
      },
      'Feeding log saved',
    );
  }

  Future<bool> recordPregnancy({
    required String farmId,
    required String animalId,
    required DateTime startDate,
    required DateTime expectedDate,
    String? notes,
  }) async {
    return _postAction(
      '/dashboard/actions/pregnancy',
      <String, dynamic>{
        'farmId': farmId,
        'animalId': animalId,
        'startDate': startDate.toIso8601String(),
        'expectedDate': expectedDate.toIso8601String(),
        'notes': notes,
      },
      'Pregnancy recorded',
    );
  }

  Future<bool> recordActivity({
    required String farmId,
    required String animalId,
    required String activity,
    required DateTime time,
    String? notes,
  }) async {
    return _postAction(
      '/dashboard/actions/activity',
      <String, dynamic>{
        'farmId': farmId,
        'animalId': animalId,
        'activity': activity,
        'time': time.toIso8601String(),
        'notes': notes,
      },
      'Activity saved',
    );
  }

  Future<bool> scanTag({
    required String farmId,
    required String animalId,
    required String tag,
  }) async {
    return _postAction(
      '/dashboard/actions/scan-tag',
      <String, dynamic>{
        'farmId': farmId,
        'animalId': animalId,
        'tag': tag,
      },
      'Tag captured',
    );
  }
}
