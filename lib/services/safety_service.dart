import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/firebase_collections.dart';

class SafetyService {
  SafetyService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(FirebaseCollections.safetyReports);

  CollectionReference<Map<String, dynamic>> _contacts(String uid) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .collection(FirebaseCollections.emergencyContacts);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEmergencyContacts() {
    final uid = _auth.currentUser?.uid ?? '_';
    return _contacts(uid).orderBy('name').snapshots();
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Utilisateur non connecte');

    await _contacts(uid).add({
      'name': name.trim(),
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _contacts(uid).doc(contactId).delete();
  }

  Future<void> sendSos({String requestId = '', String message = ''}) async {
    await _createReport(
      type: 'sos',
      requestId: requestId,
      message: message.trim().isEmpty
          ? 'Bouton SOS declenche depuis MotoFix Niger'
          : message.trim(),
    );
  }

  Future<void> sendSignalement({
    required String message,
    String requestId = '',
  }) async {
    await _createReport(
      type: 'signalement',
      requestId: requestId,
      message: message.trim(),
    );
  }

  Future<void> _createReport({
    required String type,
    required String requestId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecte');

    final location = await _tryCurrentLocation();
    await _reports.add({
      'userId': user.uid,
      'email': user.email ?? '',
      'requestId': requestId,
      'type': type,
      'message': message,
      'location': location,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<GeoPoint?> _tryCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}
