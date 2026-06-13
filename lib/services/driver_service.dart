import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../models/request_model.dart';

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.uid,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.plateNumber,
    required this.rating,
    required this.available,
    required this.active,
  });

  final String id;
  final String uid;
  final String name;
  final String phone;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final bool available;
  final bool active;

  String get displayName => name.trim().isEmpty ? 'Chauffeur MotoFix' : name;

  factory DriverProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return DriverProfile(
      id: doc.id,
      uid: data['uid']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      vehicle:
          data['vehicle']?.toString() ??
          data['vehicleType']?.toString() ??
          'Moto',
      plateNumber: data['plateNumber']?.toString() ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      available: data['available'] as bool? ?? true,
      active: data['active'] as bool? ?? true,
    );
  }
}

class DriverService {
  DriverService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Chauffeur non connecte');
    }
    return uid;
  }

  Future<void> ensureDriverProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Chauffeur non connecte');
    }

    final driverRef = _drivers.doc(user.uid);
    final existingDriver = await driverRef.get();
    if (existingDriver.exists) return;

    final userDoc = await _users.doc(user.uid).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};

    await driverRef.set({
      'uid': user.uid,
      'name': userData['name']?.toString().trim().isNotEmpty == true
          ? userData['name']
          : user.displayName ?? 'Chauffeur MotoFix',
      'email': user.email ?? userData['email']?.toString() ?? '',
      'phone': userData['phone']?.toString() ?? '',
      'vehicle': userData['vehicle']?.toString() ?? 'Moto',
      'vehicleType': userData['vehicleType']?.toString() ?? 'Moto',
      'plateNumber': userData['plateNumber']?.toString() ?? '',
      'rating': 4.8,
      'active': true,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DriverProfile?> watchCurrentDriver() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _drivers.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DriverProfile.fromDoc(doc);
    });
  }

  Stream<List<RequestModel>> watchAvailableRequests() {
    return _requests
        .where('status', isEqualTo: RequestStatus.pending)
        .limit(40)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            return RequestModel.fromMap(doc.id, doc.data());
          }).toList();
          requests.sort(_sortByRecent);
          return requests;
        });
  }

  Stream<List<RequestModel>> watchDriverRequests(String driverId) {
    return _requests
        .where('driverId', isEqualTo: driverId)
        .limit(60)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            return RequestModel.fromMap(doc.id, doc.data());
          }).toList();
          requests.sort(_sortByRecent);
          return requests;
        });
  }

  Future<void> acceptRequest({
    required RequestModel request,
    required DriverProfile driver,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _requests.doc(request.id);
      final requestSnap = await transaction.get(requestRef);
      final data = requestSnap.data();

      if (!requestSnap.exists || data == null) {
        throw StateError('Demande introuvable');
      }

      final current = RequestModel.fromMap(requestSnap.id, data);
      if (current.status != RequestStatus.pending) {
        throw StateError('Cette demande a deja ete prise');
      }

      transaction.update(requestRef, {
        'driverId': driver.id,
        'driverName': driver.displayName,
        'driverPhone': driver.phone,
        'driverVehicle': driver.vehicle,
        'driverPlate': driver.plateNumber,
        'status': RequestStatus.accepted,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(_drivers.doc(driver.id), {
        'available': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> refuseRequest(String requestId) {
    return _requests.doc(requestId).update({
      'status': RequestStatus.refused,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startRequest(String requestId) {
    return _requests.doc(requestId).update({
      'status': RequestStatus.inProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> arriveAtPickup(String requestId) {
    return _requests.doc(requestId).update({
      'status': RequestStatus.arrived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeRequest(String requestId) async {
    final batch = _firestore.batch();
    batch.update(_requests.doc(requestId), {
      'status': RequestStatus.completed,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_drivers.doc(_currentUid), {
      'available': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> setAvailability(bool available) {
    return _drivers.doc(_currentUid).set({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Position> syncCurrentLocation() async {
    final locationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationEnabled) {
      throw StateError('Activez la localisation du telephone');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Permission de localisation refusee');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final location = GeoPoint(position.latitude, position.longitude);

    await _drivers.doc(_currentUid).set({
      'currentLocation': location,
      'lastLocationAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final activeRequests = await _requests
        .where('driverId', isEqualTo: _currentUid)
        .where('status', whereIn: [
          RequestStatus.accepted,
          RequestStatus.inProgress,
          RequestStatus.arrived,
        ])
        .limit(5)
        .get();

    if (activeRequests.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in activeRequests.docs) {
        batch.update(doc.reference, {
          'driverLocation': location,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    return position;
  }

  int _sortByRecent(RequestModel a, RequestModel b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
