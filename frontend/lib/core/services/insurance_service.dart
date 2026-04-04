import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../network/api_base.dart';
import 'storage_service.dart';

class InsuranceProviderEntry {
  final String id;
  final String name;
  final String country;
  final String? phone;
  final String? whatsapp;
  final String? website;
  final String? email;
  final String coverageSummary;
  final List<String> supportedAnimalTypes;

  InsuranceProviderEntry({
    required this.id,
    required this.name,
    required this.country,
    required this.phone,
    required this.whatsapp,
    required this.website,
    required this.email,
    required this.coverageSummary,
    required this.supportedAnimalTypes,
  });

  factory InsuranceProviderEntry.fromJson(Map<String, dynamic> json) {
    return InsuranceProviderEntry(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown provider').toString(),
      country: (json['country'] ?? '').toString().toUpperCase(),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      website: json['website']?.toString(),
      email: json['email']?.toString(),
      coverageSummary: (json['coverageSummary'] ?? 'Coverage details not available').toString(),
      supportedAnimalTypes: (json['supportedAnimalTypes'] is List)
          ? (json['supportedAnimalTypes'] as List).map((item) => item.toString().toUpperCase()).toList()
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'phone': phone,
      'whatsapp': whatsapp,
      'website': website,
      'email': email,
      'coverageSummary': coverageSummary,
      'supportedAnimalTypes': supportedAnimalTypes,
    };
  }
}

class InsuranceService {
  static const String _savedProvidersKey = 'insurance_saved_provider_ids';

  String _cacheKey(String country, String animalType) {
    return 'insurance_${country.toUpperCase()}_${animalType.toUpperCase()}';
  }

  Future<List<InsuranceProviderEntry>> fetchProviders({
    required String country,
    required String animalType,
  }) async {
    final normalizedCountry = country.trim().toUpperCase();
    final normalizedAnimalType = animalType.trim().toUpperCase();

    final storage = await StorageService.getInstance();
    final cacheKey = _cacheKey(normalizedCountry, normalizedAnimalType);
    final cached = storage.getCachedData(cacheKey);

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        return _fromCached(cached);
      }

      final response = await http.get(
        ApiBase.uri(
          '/insurance/providers',
          queryParameters: {
            'country': normalizedCountry,
            'animal_type': normalizedAnimalType,
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = (body['data'] as List?) ?? <dynamic>[];
        final items = data
            .whereType<Map>()
            .map((item) => InsuranceProviderEntry.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        await storage.cacheData(
          cacheKey,
          {
            'items': items.map((item) => item.toJson()).toList(),
          },
          expiration: const Duration(days: 7),
        );

        return items;
      }

      return _fromCached(cached);
    } catch (_) {
      return _fromCached(cached);
    }
  }

  List<InsuranceProviderEntry> _fromCached(Map<String, dynamic>? cached) {
    if (cached == null) return <InsuranceProviderEntry>[];
    final rawItems = cached['items'];
    if (rawItems is! List) return <InsuranceProviderEntry>[];

    return rawItems
        .whereType<Map>()
        .map((item) => InsuranceProviderEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> preloadProviders({
    required String country,
    required List<String> animalTypes,
  }) async {
    for (final type in animalTypes) {
      await fetchProviders(country: country, animalType: type);
    }
  }

  Future<Set<String>> getSavedProviderIds() async {
    final storage = await StorageService.getInstance();
    final list = storage.getStringList(_savedProvidersKey) ?? <String>[];
    return list.toSet();
  }

  Future<void> toggleSavedProvider(String providerId) async {
    final storage = await StorageService.getInstance();
    final set = await getSavedProviderIds();
    if (set.contains(providerId)) {
      set.remove(providerId);
    } else {
      set.add(providerId);
    }
    await storage.saveStringList(_savedProvidersKey, set.toList());
  }
}
