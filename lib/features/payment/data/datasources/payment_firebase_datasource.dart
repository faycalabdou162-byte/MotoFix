import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../models/feature_models.dart';

class PaymentFirebaseDataSource {
  PaymentFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection(FirebaseCollections.payments);

  Stream<List<PaymentModel>> watchUserPayments(String uid, {int limit = 30}) {
    return _payments
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentModel.fromDoc).toList());
  }

  Stream<List<PaymentModel>> watchDriverPayments(
    String driverId, {
    int limit = 80,
  }) {
    return _payments
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentModel.fromDoc).toList());
  }

  Stream<List<PaymentModel>> watchRecentPayments({int limit = 40}) {
    return _payments
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentModel.fromDoc).toList());
  }

  Future<String> createPayment({
    required String userId,
    required String requestId,
    required int amount,
    required String method,
    required String phone,
    String driverId = '',
  }) async {
    final doc = await _payments.add({
      'userId': userId,
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

  Future<void> updateStatus(String paymentId, String status) {
    return _payments.doc(paymentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String? get currentUid => _auth.currentUser?.uid;
}
