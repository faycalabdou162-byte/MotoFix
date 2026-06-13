import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_collections.dart';

class DriverVerificationService {
  DriverVerificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection(FirebaseCollections.driverVerifications)
        .doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMine() {
    final uid = _auth.currentUser?.uid ?? '_';
    return _doc(uid).snapshots();
  }

  Future<void> submit({
    required String cni,
    required String permis,
    required String carteGrise,
    required String vehiclePhotoUrl,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Chauffeur non connecte');

    return _doc(uid).set({
      'driverId': uid,
      'cni': cni.trim(),
      'permis': permis.trim(),
      'carteGrise': carteGrise.trim(),
      'vehiclePhotoUrl': vehiclePhotoUrl.trim(),
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
