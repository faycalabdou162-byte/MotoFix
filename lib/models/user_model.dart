import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  static const admin = 'admin';
  static const client = 'client';
  static const driver = 'driver';

  static String normalize(String? role) {
    if (role == admin || role == driver) return role!;
    return client;
  }
}

class UserStatus {
  static const active = 'active';
  static const suspended = 'suspended';

  static String normalize(String? status) {
    if (status == suspended) return suspended;
    return active;
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.notificationsEnabled,
    required this.language,
    required this.darkMode,
    required this.phoneVerified,
    required this.defaultAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool notificationsEnabled;
  final String language;
  final bool darkMode;
  final bool phoneVerified;
  final String defaultAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isSuspended => status == UserStatus.suspended;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: UserRole.normalize(map['role']?.toString()),
      status: UserStatus.normalize(map['status']?.toString()),
      notificationsEnabled: map['notificationsEnabled'] is bool
          ? map['notificationsEnabled'] as bool
          : true,
      language: map['language']?.toString() ?? 'fr',
      darkMode: map['darkMode'] is bool ? map['darkMode'] as bool : true,
      phoneVerified: map['phoneVerified'] is bool
          ? map['phoneVerified'] as bool
          : false,
      defaultAddress: map['defaultAddress']?.toString() ?? 'Niamey, Niger',
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'darkMode': darkMode,
      'phoneVerified': phoneVerified,
      'defaultAddress': defaultAddress,
    };
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
