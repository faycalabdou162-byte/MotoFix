import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageType {
  static const text = 'text';
  static const location = 'location';
  static const photo = 'photo';
  static const voice = 'voice';

  static const all = {text, location, photo, voice};

  static String label(String type) {
    return switch (type) {
      location => 'Position',
      photo => 'Photo de panne',
      voice => 'Message vocal',
      _ => 'Message',
    };
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.type,
    required this.text,
    required this.photoUrl,
    required this.voiceUrl,
    required this.location,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String type;
  final String text;
  final String photoUrl;
  final String voiceUrl;
  final GeoPoint? location;
  final DateTime? createdAt;

  factory ChatMessageModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'MotoFix',
      senderRole: data['senderRole']?.toString() ?? 'client',
      type: data['type']?.toString() ?? ChatMessageType.text,
      text: data['text']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      voiceUrl: data['voiceUrl']?.toString() ?? '',
      location: data['location'] is GeoPoint ? data['location'] as GeoPoint : null,
      createdAt: _dateFromValue(data['createdAt']),
    );
  }
}

class PaymentMethod {
  static const cash = 'cash';
  static const airtelMoney = 'airtel_money';
  static const zamaniCash = 'zamani_cash';
  static const moovMoney = 'moov_money';
  static const card = 'card';

  static const all = {cash, airtelMoney, zamaniCash, moovMoney, card};

  static String label(String method) {
    return switch (method) {
      cash => 'Especes',
      airtelMoney => 'Airtel Money',
      zamaniCash => 'Zamani Cash',
      moovMoney => 'Moov Money',
      card => 'Carte bancaire',
      _ => 'Paiement',
    };
  }
}

class PaymentStatus {
  static const pending = 'pending';
  static const paid = 'paid';
  static const failed = 'failed';

  static String label(String status) {
    return switch (status) {
      paid => 'Recu',
      failed => 'Echec',
      _ => 'En attente',
    };
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.driverId,
    required this.amount,
    required this.method,
    required this.status,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String requestId;
  final String driverId;
  final int amount;
  final String method;
  final String status;
  final String phone;
  final DateTime? createdAt;

  factory PaymentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PaymentModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      requestId: data['requestId']?.toString() ?? '',
      driverId: data['driverId']?.toString() ?? '',
      amount: _intFromValue(data['amount']),
      method: data['method']?.toString() ?? PaymentMethod.cash,
      status: data['status']?.toString() ?? PaymentStatus.pending,
      phone: data['phone']?.toString() ?? '',
      createdAt: _dateFromValue(data['createdAt']),
    );
  }
}

class ServiceZoneModel {
  const ServiceZoneModel({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;

  factory ServiceZoneModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ServiceZoneModel(
      id: doc.id,
      name: data['name']?.toString() ?? doc.id,
      active: data['active'] as bool? ?? true,
    );
  }
}

class MaintenanceConfig {
  const MaintenanceConfig({
    required this.maintenanceMode,
    required this.serverAvailable,
    required this.forceUpdate,
    required this.message,
    required this.updateUrl,
  });

  final bool maintenanceMode;
  final bool serverAvailable;
  final bool forceUpdate;
  final String message;
  final String updateUrl;

  bool get blocksApp => maintenanceMode || !serverAvailable || forceUpdate;

  factory MaintenanceConfig.fromMap(Map<String, dynamic>? data) {
    return MaintenanceConfig(
      maintenanceMode: data?['maintenanceMode'] as bool? ?? false,
      serverAvailable: data?['serverAvailable'] as bool? ?? true,
      forceUpdate: data?['forceUpdate'] as bool? ?? false,
      message:
          data?['message']?.toString() ??
          'MotoFix Niger est temporairement indisponible.',
      updateUrl: data?['updateUrl']?.toString() ?? '',
    );
  }
}

DateTime? _dateFromValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

int _intFromValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}
