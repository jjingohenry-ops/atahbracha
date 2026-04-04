import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_base.dart';

class RemindersProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? successMessage;
  List<Map<String, dynamic>> reminders = [];
  DateTime? selectedDate;
  String? selectedFarmId;

  Future<void> fetchReminders({DateTime? date, String? farmId}) async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        isLoading = false;
        notifyListeners();
        return;
      }

      selectedFarmId = farmId;
      final uri = ApiBase.uri(
        '/reminders',
        queryParameters: {
          if (date != null) 'date': date.toIso8601String().split('T').first,
          if (farmId != null && farmId.isNotEmpty) 'farmId': farmId,
        },
      );
      http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out. Check if backend is running on port 3000.'),
      );

      if (response.statusCode == 403 && farmId != null && farmId.isNotEmpty) {
        final fallbackUri = ApiBase.uri(
          '/reminders',
          queryParameters: {
            if (date != null) 'date': date.toIso8601String().split('T').first,
          },
        );

        response = await http.get(
          fallbackUri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Connection timed out. Check if backend is running on port 3000.'),
        );
      }

      if (response.statusCode == 200) {
        dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> fetched = List<Map<String, dynamic>>.from(
          data['data'] ?? <Map<String, dynamic>>[],
        );

        final bool hasFarmFilter = farmId != null && farmId.isNotEmpty;
        if (hasFarmFilter && fetched.isEmpty) {
          final fallbackUri = ApiBase.uri(
            '/reminders',
            queryParameters: {
              if (date != null) 'date': date.toIso8601String().split('T').first,
            },
          );

          final fallbackResponse = await http.get(
            fallbackUri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Connection timed out. Check if backend is running on port 3000.'),
          );

          if (fallbackResponse.statusCode == 200) {
            final dynamic fallbackData = json.decode(fallbackResponse.body);
            final List<Map<String, dynamic>> fallbackFetched =
                List<Map<String, dynamic>>.from(
              fallbackData['data'] ?? <Map<String, dynamic>>[],
            );
            if (fallbackFetched.isNotEmpty) {
              data = fallbackData;
              fetched = fallbackFetched;
            }
          }
        }

        reminders = fetched;
        error = null; // No error if we got data (even if empty array)
      } else if (response.statusCode >= 500) {
        error = 'Oops! Server error. Please try again later.';
      } else if (response.statusCode >= 400) {
        error = 'Oops! Unable to load reminders. Check your connection.';
      } else {
        error = 'Oops! Unable to load reminders.';
      }
    } on TimeoutException catch (e) {
      error = e.message;
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        error = 'Cannot connect to server. Is the backend running on port 3000?';
      } else if (e.toString().contains('Network is unreachable')) {
        error = 'No internet connection';
      } else {
        error = 'Error loading reminders: ${e.toString()}';
      }
    }
    isLoading = false;
    notifyListeners();
  }

  void filterByDate(DateTime date, {String? farmId}) {
    selectedDate = date;
    fetchReminders(date: date, farmId: farmId ?? selectedFarmId);
  }

  Future<bool> addReminder(Map<String, dynamic> reminder, {String? farmId}) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        notifyListeners();
        return false;
      }

      final targetFarmId = farmId ?? selectedFarmId;
      if (targetFarmId == null || targetFarmId.isEmpty) {
        error = 'Select a farm before adding reminders';
        notifyListeners();
        return false;
      }

      final response = await http.post(
        ApiBase.uri('/reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          ...reminder,
          'farmId': targetFarmId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );
      if (response.statusCode == 201) {
        // refresh list for current date
        successMessage = 'Reminder added successfully!';
        await fetchReminders(date: selectedDate, farmId: targetFarmId);
        notifyListeners();
        return true;
      } else if (response.statusCode >= 500) {
        error = 'Server error. Please try again.';
      } else if (response.statusCode == 400) {
        error = 'Invalid reminder data. Please check your inputs.';
      } else {
        error = 'Failed to add reminder';
      }
    } on TimeoutException {
      error = 'Request timed out. Is the backend running?';
    } catch (e) {
      error = 'Error adding reminder: ${e.toString()}';
    }
    notifyListeners();
    return false;
  }

  Future<bool> completeReminder(String reminderId, {String? farmId}) async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();

    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        return false;
      }

      final http.Response response = await http.delete(
        ApiBase.uri('/reminders/$reminderId'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      if (response.statusCode == 200) {
        successMessage = 'Reminder completed';
        await fetchReminders(date: selectedDate, farmId: farmId ?? selectedFarmId);
        return true;
      }

      if (response.statusCode == 404) {
        error = 'Reminder not found';
      } else if (response.statusCode >= 500) {
        error = 'Server error. Please try again.';
      } else {
        error = 'Failed to complete reminder';
      }
      return false;
    } on TimeoutException {
      error = 'Request timed out. Is the backend running?';
      return false;
    } catch (e) {
      error = 'Error completing reminder: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
