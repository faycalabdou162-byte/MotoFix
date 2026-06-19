import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../models/user_model.dart';

class ProfileFirebaseDataSource {
  ProfileFirebaseDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _user(String uid) {
    return _firestore.collection(FirebaseCollections.users).doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _addresses(String uid) {
    return _user(uid).collection(FirebaseCollections.addresses);
  }

  Stream<UserModel?> watchProfile(String uid) {
    return _user(uid).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return UserModel.fromMap({...data, 'uid': uid});
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String defaultAddress,
  }) {
    return _user(uid).update({
      'name': name,
      'phone': phone,
      'defaultAddress': defaultAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNotificationsEnabled({
    required String uid,
    required bool enabled,
  }) {
    return _user(uid).update({
      'notificationsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveFcmToken({required String uid, required String token}) {
    return _user(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchAddresses(String uid) {
    return _addresses(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> addAddress({
    required String uid,
    required String label,
    required String address,
  }) {
    return _addresses(uid).add({
      'label': label.trim(),
      'address': address.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAddress({
    required String uid,
    required String addressId,
  }) {
    return _addresses(uid).doc(addressId).delete();
  }
}
