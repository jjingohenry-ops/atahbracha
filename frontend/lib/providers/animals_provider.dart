import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnimalsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<dynamic> animals = [];

  Future<void> fetchAnimals() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/animals'));
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
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/animals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(animal),
      );
      if (response.statusCode == 201) {
        await fetchAnimals();
        return true;
      } else {
        error = 'Failed to add animal';
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
    return false;
  }
}
