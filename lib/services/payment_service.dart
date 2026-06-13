import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_collections.dart';
import '../models/feature_models.dart';

class PaymentService {
  PaymentService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection(FirebaseCollections.payments);

  Stream<List<PaymentModel>> watchCurrentUserPayments({int limit = 30}) {
    final uid = _auth.currentUser?.uid ?? '_';
    return _payments
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(PaymentModel.fromDoc).toList();
        });
  }

  Stream<List<PaymentModel>> watchDriverPayments(String driverId) {
    return _payments
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(PaymentModel.fromDoc).toList();
        });
  }

  Stream<List<PaymentModel>> watchRecentPayments({int limit = 40}) {
    return _payments
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(PaymentModel.fromDoc).toList();
        });
  }

  Future<String> createPayment({
    required String requestId,
    required int amount,
    required String method,
    required String phone,
    String driverId = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecte');
    }

    if (!PaymentMethod.all.contains(method)) {
      throw ArgumentError.value(method, 'method', 'Methode invalide');
    }

    final doc = await _payments.add({
      'userId': user.uid,
      'requestId': requestId,
      'driverId': driverId,
      'amount': amount,
      'method': method,
      'phone': phone.trim(),
      'status': PaymentStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> markPaid(String paymentId) {
    return _payments.doc(paymentId).update({
      'status': PaymentStatus.paid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markFailed(String paymentId) {
    return _payments.doc(paymentId).update({
      'status': PaymentStatus.failed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
