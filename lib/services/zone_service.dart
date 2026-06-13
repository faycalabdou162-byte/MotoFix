import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_collections.dart';
import '../models/feature_models.dart';

class ZoneService {
  ZoneService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const defaultCities = ['Niamey', 'Maradi', 'Zinder', 'Tahoua', 'Agadez'];

  CollectionReference<Map<String, dynamic>> get _zones =>
      _firestore.collection(FirebaseCollections.serviceZones);

  Stream<List<ServiceZoneModel>> watchZones() {
    return _zones.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(ServiceZoneModel.fromDoc).toList();
    });
  }

  Future<void> seedDefaultZones() async {
    final batch = _firestore.batch();
    for (final city in defaultCities) {
      final ref = _zones.doc(city.toLowerCase());
      batch.set(ref, {
        'name': city,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> setZoneActive(String zoneId, bool active) {
    return _zones.doc(zoneId).set({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
