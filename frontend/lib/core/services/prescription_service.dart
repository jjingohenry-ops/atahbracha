import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../network/api_base.dart';
import 'storage_service.dart';

class PrescriptionItemEntry {
  final String id;
  final String drugName;
  final String dosage;
  final int frequencyPerDay;
  final int durationDays;
  final int? withdrawalPeriodDays;
  final int totalDoses;
  final int completedDoses;
  final int remainingDoses;
  final double progress;
  final String status;
  final String statusColor;
  final DateTime? nextDoseAt;

  PrescriptionItemEntry({
    required this.id,
    required this.drugName,
    required this.dosage,
    required this.frequencyPerDay,
    required this.durationDays,
    required this.withdrawalPeriodDays,
    required this.totalDoses,
    required this.completedDoses,
    required this.remainingDoses,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.nextDoseAt,
  });

  factory PrescriptionItemEntry.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemEntry(
      id: (json['id'] ?? '').toString(),
      drugName: (json['drugName'] ?? 'Unknown drug').toString(),
      dosage: (json['dosage'] ?? '-').toString(),
      frequencyPerDay: (json['frequencyPerDay'] is num)
          ? (json['frequencyPerDay'] as num).toInt()
          : int.tryParse('${json['frequencyPerDay']}') ?? 1,
      durationDays: (json['durationDays'] is num)
          ? (json['durationDays'] as num).toInt()
          : int.tryParse('${json['durationDays']}') ?? 1,
      withdrawalPeriodDays: (json['withdrawalPeriodDays'] is num)
          ? (json['withdrawalPeriodDays'] as num).toInt()
          : int.tryParse('${json['withdrawalPeriodDays']}'),
      totalDoses: (json['totalDoses'] is num)
          ? (json['totalDoses'] as num).toInt()
          : int.tryParse('${json['totalDoses']}') ?? 1,
      completedDoses: (json['completedDoses'] is num)
          ? (json['completedDoses'] as num).toInt()
          : int.tryParse('${json['completedDoses']}') ?? 0,
      remainingDoses: (json['remainingDoses'] is num)
          ? (json['remainingDoses'] as num).toInt()
          : int.tryParse('${json['remainingDoses']}') ?? 0,
      progress: (json['progress'] is num)
          ? (json['progress'] as num).toDouble()
          : double.tryParse('${json['progress']}') ?? 0,
      status: (json['status'] ?? 'ACTIVE').toString().toUpperCase(),
      statusColor: (json['statusColor'] ?? 'YELLOW').toString().toUpperCase(),
      nextDoseAt: json['nextDoseAt'] != null ? DateTime.tryParse(json['nextDoseAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drugName': drugName,
      'dosage': dosage,
      'frequencyPerDay': frequencyPerDay,
      'durationDays': durationDays,
      'withdrawalPeriodDays': withdrawalPeriodDays,
      'totalDoses': totalDoses,
      'completedDoses': completedDoses,
      'remainingDoses': remainingDoses,
      'progress': progress,
      'status': status,
      'statusColor': statusColor,
      'nextDoseAt': nextDoseAt?.toIso8601String(),
    };
  }
}

class PrescriptionEntry {
  final String id;
  final String animalId;
  final String diagnosis;
  final String? vetName;
  final String? notes;
  final String status;
  final double progress;
  final DateTime createdAt;
  final List<PrescriptionItemEntry> items;

  PrescriptionEntry({
    required this.id,
    required this.animalId,
    required this.diagnosis,
    required this.vetName,
    required this.notes,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.items,
  });

  factory PrescriptionEntry.fromJson(Map<String, dynamic> json) {
    return PrescriptionEntry(
      id: (json['id'] ?? '').toString(),
      animalId: (json['animalId'] ?? '').toString(),
      diagnosis: (json['diagnosis'] ?? 'No diagnosis').toString(),
      vetName: json['vetName']?.toString(),
      notes: json['notes']?.toString(),
      status: (json['status'] ?? 'ACTIVE').toString().toUpperCase(),
      progress: (json['progress'] is num)
          ? (json['progress'] as num).toDouble()
          : double.tryParse('${json['progress']}') ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      items: (json['items'] is List)
          ? (json['items'] as List)
              .whereType<Map>()
              .map((item) => PrescriptionItemEntry.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <PrescriptionItemEntry>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animalId': animalId,
      'diagnosis': diagnosis,
      'vetName': vetName,
      'notes': notes,
      'status': status,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class PrescriptionService {
  static const String _queueKey = 'prescription_offline_queue';

  String _cacheKeyForAnimal(String animalId) => 'prescriptions_animal_$animalId';

  Future<String?> _token() async {
    final dynamic rawToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final String token = rawToken?.toString() ?? '';
    if (token.trim().isEmpty) return null;
    return token;
  }

  Future<List<PrescriptionEntry>> fetchByAnimal(String animalId) async {
    final storage = await StorageService.getInstance();
    final cached = storage.getCachedData(_cacheKeyForAnimal(animalId));

    try {
      final token = await _token();
      if (token == null) return _fromCache(cached);

      final response = await http.get(
        ApiBase.uri('/prescriptions/animal/$animalId'),
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
            .map((raw) => PrescriptionEntry.fromJson(Map<String, dynamic>.from(raw)))
            .toList();

        await storage.cacheData(
          _cacheKeyForAnimal(animalId),
          {'items': items.map((e) => e.toJson()).toList()},
          expiration: const Duration(days: 14),
        );

        return items;
      }

      return _fromCache(cached);
    } catch (_) {
      return _fromCache(cached);
    }
  }

  List<PrescriptionEntry> _fromCache(Map<String, dynamic>? cached) {
    if (cached == null) return <PrescriptionEntry>[];
    final items = cached['items'];
    if (items is! List) return <PrescriptionEntry>[];

    return items
        .whereType<Map>()
        .map((raw) => PrescriptionEntry.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<bool> createPrescription({
    required String animalId,
    required String diagnosis,
    String? vetName,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await _token();

    if (token == null) {
      await _enqueueOperation({
        'type': 'create-prescription',
        'payload': {
          'animalId': animalId,
          'diagnosis': diagnosis,
          'vetName': vetName,
          'notes': notes,
          'items': items,
        },
      });
      return true;
    }

    try {
      final response = await http.post(
        ApiBase.uri('/prescriptions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'animalId': animalId,
          'diagnosis': diagnosis,
          'vetName': vetName,
          'notes': notes,
          'items': items,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchByAnimal(animalId);
        return true;
      }

      await _enqueueOperation({
        'type': 'create-prescription',
        'payload': {
          'animalId': animalId,
          'diagnosis': diagnosis,
          'vetName': vetName,
          'notes': notes,
          'items': items,
        },
      });
      return true;
    } catch (_) {
      await _enqueueOperation({
        'type': 'create-prescription',
        'payload': {
          'animalId': animalId,
          'diagnosis': diagnosis,
          'vetName': vetName,
          'notes': notes,
          'items': items,
        },
      });
      return true;
    }
  }

  Future<bool> markDoseGiven({
    required String animalId,
    required String prescriptionId,
    required String itemId,
    DateTime? scheduledFor,
  }) async {
    final token = await _token();

    if (token == null) {
      await _enqueueOperation({
        'type': 'mark-dose-given',
        'payload': {
          'prescriptionId': prescriptionId,
          'itemId': itemId,
          'scheduledFor': scheduledFor?.toIso8601String(),
        },
      });
      await _applyLocalMarkGiven(animalId, prescriptionId, itemId);
      return true;
    }

    try {
      final response = await http.post(
        ApiBase.uri('/prescriptions/$prescriptionId/items/$itemId/mark-given'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'scheduledFor': scheduledFor?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchByAnimal(animalId);
        return true;
      }

      await _enqueueOperation({
        'type': 'mark-dose-given',
        'payload': {
          'prescriptionId': prescriptionId,
          'itemId': itemId,
          'scheduledFor': scheduledFor?.toIso8601String(),
        },
      });
      await _applyLocalMarkGiven(animalId, prescriptionId, itemId);
      return true;
    } catch (_) {
      await _enqueueOperation({
        'type': 'mark-dose-given',
        'payload': {
          'prescriptionId': prescriptionId,
          'itemId': itemId,
          'scheduledFor': scheduledFor?.toIso8601String(),
        },
      });
      await _applyLocalMarkGiven(animalId, prescriptionId, itemId);
      return true;
    }
  }

  Future<void> syncPendingOperations() async {
    final token = await _token();
    if (token == null) return;

    final storage = await StorageService.getInstance();
    final queue = storage.getStringList(_queueKey) ?? <String>[];
    if (queue.isEmpty) return;

    final List<String> failed = <String>[];

    for (final raw in queue) {
      try {
        final operation = json.decode(raw);
        final type = (operation['type'] ?? '').toString();

        if (type == 'create-prescription') {
          final response = await http.post(
            ApiBase.uri('/prescriptions'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(operation['payload']),
          );

          if (response.statusCode < 200 || response.statusCode >= 300) {
            failed.add(raw);
          }
          continue;
        }

        if (type == 'mark-dose-given') {
          final response = await http.post(
            ApiBase.uri('/prescriptions/sync'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'operations': <dynamic>[operation]}),
          );

          if (response.statusCode < 200 || response.statusCode >= 300) {
            failed.add(raw);
            continue;
          }

          final body = json.decode(response.body);
          final data = body['data'];
          if (data is List && data.isNotEmpty) {
            final first = data.first;
            if (first is Map && first['success'] == false) {
              failed.add(raw);
            }
          }
          continue;
        }

        failed.add(raw);
      } catch (_) {
        failed.add(raw);
      }
    }

    await storage.saveStringList(_queueKey, failed);
  }

  Future<void> _enqueueOperation(Map<String, dynamic> operation) async {
    final storage = await StorageService.getInstance();
    final queue = storage.getStringList(_queueKey) ?? <String>[];
    queue.add(json.encode(operation));
    await storage.saveStringList(_queueKey, queue);
  }

  Future<void> _applyLocalMarkGiven(String animalId, String prescriptionId, String itemId) async {
    final storage = await StorageService.getInstance();
    final key = _cacheKeyForAnimal(animalId);
    final cached = storage.getCachedData(key);
    final current = _fromCache(cached);

    final updated = current.map((prescription) {
      if (prescription.id != prescriptionId) return prescription;

      final items = prescription.items.map((item) {
        if (item.id != itemId) return item;

        final completedDoses = item.completedDoses + 1 > item.totalDoses
            ? item.totalDoses
            : item.completedDoses + 1;
        final remaining = item.totalDoses - completedDoses;
        final progress = item.totalDoses <= 0 ? 1.0 : completedDoses / item.totalDoses;

        return PrescriptionItemEntry(
          id: item.id,
          drugName: item.drugName,
          dosage: item.dosage,
          frequencyPerDay: item.frequencyPerDay,
          durationDays: item.durationDays,
          withdrawalPeriodDays: item.withdrawalPeriodDays,
          totalDoses: item.totalDoses,
          completedDoses: completedDoses,
          remainingDoses: remaining < 0 ? 0 : remaining,
          progress: progress,
          status: remaining <= 0 ? 'COMPLETED' : item.status,
          statusColor: remaining <= 0 ? 'GREEN' : item.statusColor,
          nextDoseAt: item.nextDoseAt,
        );
      }).toList();

      final totalProgress = items.isEmpty
          ? 0.0
          : items.map((i) => i.progress).reduce((a, b) => a + b) / items.length;

      return PrescriptionEntry(
        id: prescription.id,
        animalId: prescription.animalId,
        diagnosis: prescription.diagnosis,
        vetName: prescription.vetName,
        notes: prescription.notes,
        status: prescription.status,
        progress: totalProgress,
        createdAt: prescription.createdAt,
        items: items,
      );
    }).toList();

    await storage.cacheData(
      key,
      {'items': updated.map((entry) => entry.toJson()).toList()},
      expiration: const Duration(days: 14),
    );
  }
}
