import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../models/request_model.dart';

/// Firestore + GPS operations for service requests.
class RequestFirebaseDataSource {
  RequestFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(FirebaseCollections.requests);

  Future<String> createRequest({
    required String type,
    String description = '',
    String pickupAddress = 'Niamey, Niger',
    String destinationAddress = '',
    int? price,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecte');
    }

    if (!RequestType.all.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Type de demande invalide');
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final profileData = profile.data() ?? const <String, dynamic>{};
    final clientName = profileData['name']?.toString().trim();
    final phone = profileData['phone']?.toString().trim();
    final pickupLocation = await _tryCurrentLocation();

    final doc = _requests.doc();
    final batch = _firestore.batch();

    batch.set(doc, {
      'type': type,
      'userId': user.uid,
      'clientName': clientName?.isNotEmpty == true
          ? clientName
          : user.displayName ?? '',
      'email': user.email ?? '',
      'phone': phone ?? '',
      'description': description.trim(),
      'pickupAddress': pickupAddress.trim().isEmpty
          ? 'Niamey, Niger'
          : pickupAddress.trim(),
      'pickupLocation': pickupLocation,
      'driverLocation': null,
      'destinationAddress': destinationAddress.trim(),
      'status': RequestStatus.pending,
      'price': price ?? (type == RequestType.taxi ? 2000 : 3000),
      'distanceKm': 0,
      'durationMinutes': 0,
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

    final notificationRef = _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .collection(FirebaseCollections.notifications)
        .doc();
    batch.set(notificationRef, {
      'title': 'Demande envoyee',
      'message': '${RequestType.label(type)} recue par MotoFix Niger.',
      'icon': type == RequestType.taxi ? 'taxi' : 'repair',
      'requestId': doc.id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return doc.id;
  }

  Stream<List<RequestModel>> watchUserRequests(String userId) {
    return _requests
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<RequestModel?> watchRequest(String requestId) {
    return _requests.doc(requestId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return RequestModel.fromMap(doc.id, data);
    });
  }

  Future<void> cancelRequest(String requestId) async {
    await _requests.doc(requestId).update({
      'status': RequestStatus.cancelled,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': FieldValue.serverTimestamp(),
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
