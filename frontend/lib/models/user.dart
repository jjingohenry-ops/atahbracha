class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.createdAt,
    this.updatedAt,
    this.lastSyncAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isAdmin => role == 'ADMIN';
  bool get isFarmer => role == 'FARMER';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? 'FARMER',
      phone: json['phone'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastSyncAt: json['lastSyncAt'] != null ? DateTime.parse(json['lastSyncAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

// Animal Model
class AnimalModel {
  final String id;
  final String type;
  final String name;
  final String gender;
  final DateTime birthDate;
  final double weight;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnimalModel({
    required this.id,
    required this.type,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      birthDate: DateTime.parse(json['birthDate'] ?? DateTime.now().toIso8601String()),
      weight: (json['weight'] ?? 0).toDouble(),
      status: json['status'] ?? 'ACTIVE',
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
      'weight': weight,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Farm Model
class FarmModel {
  final String id;
  final String name;
  final String location;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      ownerId: json['ownerId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
