import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/network/api_base.dart';

class AnimalsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<dynamic> animals = [];

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      final message = body['error'] ?? body['message'] ?? body['details']?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Ignore JSON parse errors and use fallback message.
    }
    return fallback;
  }

  Future<void> fetchAnimals({String? farmId}) async {
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
        '/animals',
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
        final data = json.decode(response.body);
        animals = data['data'];
      } else {
        error = 'Failed to load animals';
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addAnimal(Map<String, dynamic> animal) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        return false;
      }

      final response = await http.post(
        ApiBase.uri('/animals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(animal),
      );
      if (response.statusCode == 201) {
        await fetchAnimals(farmId: animal['farmId']?.toString());
        return true;
      } else {
        error = _extractErrorMessage(response, 'Failed to add animal');
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return false;
  }

  Future<bool> updateAnimal(String animalId, Map<String, dynamic> updates, {String? farmId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        return false;
      }

      final response = await http.put(
        ApiBase.uri('/animals/$animalId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        await fetchAnimals(farmId: farmId);
        return true;
      }

      error = _extractErrorMessage(response, 'Failed to update animal');
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return false;
  }

  Future<String?> uploadAnimalPhoto(XFile photoFile) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        error = 'Authentication required';
        notifyListeners();
        return null;
      }

      final uri = ApiBase.uri('/animals/upload-photo');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      final photoBytes = await photoFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: photoFile.name,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']?['photoUrl'] as String?;
      }

      error = _extractErrorMessage(response, 'Failed to upload photo');
      notifyListeners();
      return null;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
