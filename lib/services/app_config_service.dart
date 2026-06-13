import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_collections.dart';
import '../models/feature_models.dart';

class AppConfigService {
  AppConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _appConfig =>
      _firestore.collection(FirebaseCollections.config).doc('app');

  Stream<MaintenanceConfig> watchMaintenanceConfig() {
    return _appConfig.snapshots().map((doc) {
      return MaintenanceConfig.fromMap(doc.data());
    });
  }

  Future<MaintenanceConfig> fetchMaintenanceConfig() async {
    final doc = await _appConfig.get();
    return MaintenanceConfig.fromMap(doc.data());
  }

  Future<void> updateMaintenanceConfig({
    required bool maintenanceMode,
    required bool serverAvailable,
    required bool forceUpdate,
    required String message,
    required String updateUrl,
  }) {
    return _appConfig.set({
      'maintenanceMode': maintenanceMode,
      'serverAvailable': serverAvailable,
      'forceUpdate': forceUpdate,
      'message': message.trim(),
      'updateUrl': updateUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
