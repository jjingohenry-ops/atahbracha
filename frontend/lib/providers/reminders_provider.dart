import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RemindersProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? successMessage;
  List<Map<String, dynamic>> reminders = [];
  DateTime? selectedDate;

  Future<void> fetchReminders({DateTime? date}) async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final uri = Uri.parse('https://atahbracha.com/api/reminders').replace(
        queryParameters: date != null
            ? {'date': date.toIso8601String().split('T').first}
            : null,
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out. Check if backend is running on port 3000.'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        reminders = List<Map<String, dynamic>>.from(data['data'] ?? []);
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

  void filterByDate(DateTime date) {
    selectedDate = date;
    fetchReminders(date: date);
  }

  Future<bool> addReminder(Map<String, dynamic> reminder) async {
    try {
      final response = await http.post(
        Uri.parse('https://atahbracha.com/api/reminders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reminder),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );
      if (response.statusCode == 201) {
        // refresh list for current date
        successMessage = 'Reminder added successfully!';
        await fetchReminders(date: selectedDate);
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
}
