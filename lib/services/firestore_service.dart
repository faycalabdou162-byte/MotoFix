import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request_model.dart';
import 'request_service.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore db;

  Future<String> createRequest({
    required String uid,
    required String email,
    required String type,
    String clientName = '',
    String phone = '',
    String description = '',
    String pickupAddress = 'Niamey, Niger',
    String destinationAddress = '',
  }) async {
    if (!RequestType.all.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Type de demande invalide');
    }

    final doc = await db.collection('requests').add({
      'userId': uid,
      'email': email.trim().toLowerCase(),
      'clientName': clientName.trim(),
      'phone': phone.trim(),
      'type': type,
      'description': description.trim(),
      'pickupAddress': pickupAddress.trim().isEmpty
          ? 'Niamey, Niger'
          : pickupAddress.trim(),
      'destinationAddress': destinationAddress.trim(),
      'status': RequestStatus.pending,
      'price': RequestService.defaultPriceFor(type),
      'driverId': '',
      'driverName': '',
      'driverPhone': '',
      'driverVehicle': '',
      'driverPlate': '',
      'adminNotes': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> updateStatus(String id, String status) async {
    if (!RequestStatus.all.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Statut invalide');
    }

    await db.collection('requests').doc(id).update({
      'status': status,
      'isActive': RequestStatus.activeStatuses.contains(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
