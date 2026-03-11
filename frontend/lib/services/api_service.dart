import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://atahbracha.com';

  // Authenticate with Firebase token
  Future<UserModel?> authenticateWithFirebase(firebase_auth.User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebaseToken': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return UserModel.fromJson(data['data']['user']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('API authentication error: $e');
      return null;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return UserModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  // Update profile
  Future<UserModel?> updateProfile(String token, Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return UserModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return null;
    }
  }

  // Change password
  Future<bool> changePassword(String token, String currentPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  // Get animals
  Future<List<dynamic>?> getAnimals(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/animals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get animals error: $e');
      return null;
    }
  }

  // Add animal
  Future<bool> addAnimal(String token, Map<String, dynamic> animalData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/animals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(animalData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Add animal error: $e');
      return false;
    }
  }

  // Sync data
  Future<bool> syncData(String token, Map<String, dynamic> syncData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(syncData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Sync data error: $e');
      return false;
    }
  }
}
