import 'package:cloud_firestore/cloud_firestore.dart';

class RequestStatus {
  static const pending = 'en_attente';
  static const accepted = 'accepte';
  static const inProgress = 'en_cours';
  static const arrived = 'arrive';
  static const completed = 'termine';
  static const refused = 'refuse';
  static const cancelled = 'annule';

  static const activeStatuses = {pending, accepted, inProgress, arrived};

  static const all = {
    pending,
    accepted,
    inProgress,
    arrived,
    completed,
    refused,
    cancelled,
  };

  static String label(String status) {
    return switch (status) {
      pending => 'En attente',
      accepted => 'Acceptee',
      inProgress => 'En route',
      arrived => 'Arrive',
      completed => 'Terminee',
      refused => 'Refusee',
      cancelled => 'Annulee',
      _ => status,
    };
  }
}

class RequestType {
  static const taxi = 'taxi';
  static const depannage = 'depannage';

  static const all = {taxi, depannage};

  static String label(String type) {
    return switch (type) {
      taxi => 'Taxi moto',
      depannage => 'Depannage',
      _ => 'Demande',
    };
  }
}

class RequestModel {
  const RequestModel({
    required this.id,
    required this.userId,
    required this.clientName,
    required this.email,
    required this.phone,
    required this.type,
    required this.description,
    required this.pickupAddress,
    required this.pickupLocation,
    required this.driverLocation,
    required this.destinationAddress,
    required this.status,
    required this.price,
    required this.distanceKm,
    required this.durationMinutes,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverVehicle,
    required this.driverPlate,
    required this.adminNotes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.cancelledAt,
  });

  final String id;
  final String userId;
  final String clientName;
  final String email;
  final String phone;
  final String type;
  final String description;
  final String pickupAddress;
  final GeoPoint? pickupLocation;
  final GeoPoint? driverLocation;
  final String destinationAddress;
  final String status;
  final int price;
  final double distanceKm;
  final int durationMinutes;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverVehicle;
  final String driverPlate;
  final String adminNotes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;

  bool get isTaxi => type == RequestType.taxi;
  bool get isDepannage => type == RequestType.depannage;
  bool get hasDriver => driverName.trim().isNotEmpty;
  bool get canCancel => RequestStatus.activeStatuses.contains(status);

  factory RequestModel.fromMap(String id, Map<String, dynamic> map) {
    return RequestModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      type: map['type']?.toString() ?? RequestType.depannage,
      description: map['description']?.toString() ?? '',
      pickupAddress: map['pickupAddress']?.toString() ?? 'Niamey, Niger',
      pickupLocation: _geoPointFromValue(map['pickupLocation']),
      driverLocation: _geoPointFromValue(map['driverLocation']),
      destinationAddress: map['destinationAddress']?.toString() ?? '',
      status: map['status']?.toString() ?? RequestStatus.pending,
      price: _intFromValue(map['price'], fallback: 0),
      distanceKm: _doubleFromValue(map['distanceKm']),
      durationMinutes: _intFromValue(map['durationMinutes'], fallback: 0),
      driverId: map['driverId']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? '',
      driverPhone: map['driverPhone']?.toString() ?? '',
      driverVehicle: map['driverVehicle']?.toString() ?? '',
      driverPlate: map['driverPlate']?.toString() ?? '',
      adminNotes: map['adminNotes']?.toString() ?? '',
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
      cancelledAt: _dateFromValue(map['cancelledAt']),
    );
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int _intFromValue(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  static double _doubleFromValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }

  static GeoPoint? _geoPointFromValue(Object? value) {
    if (value is GeoPoint) return value;
    return null;
  }
}
