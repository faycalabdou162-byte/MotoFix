import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firebase_collections.dart';
import '../../models/request_model.dart';
import 'location_service.dart';

/// Finds the nearest available mechanic (driver) for a client request.
/// Uses existing `drivers` collection — not renamed to preserve Firestore data.
class MechanicMatchingService {
  MechanicMatchingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection(FirebaseCollections.drivers);

  /// Returns nearest available driver doc id + distance, or null if none.
  Future<({String driverId, double distanceKm})?> findNearest({
    required GeoPoint pickup,
    double maxRadiusKm = 15,
  }) async {
    final snapshot = await _drivers
        .where('available', isEqualTo: true)
        .where('active', isEqualTo: true)
        .limit(50)
        .get();

    String? bestId;
    double bestDistance = double.infinity;

    for (final doc in snapshot.docs) {
      final location = doc.data()['currentLocation'];
      if (location is! GeoPoint) continue;

      final distance = LocationService.distanceKm(pickup, location);
      if (distance <= maxRadiusKm && distance < bestDistance) {
        bestDistance = distance;
        bestId = doc.id;
      }
    }

    if (bestId == null) return null;
    return (driverId: bestId, distanceKm: bestDistance);
  }

  /// Assigns nearest mechanic metadata on a pending request (admin/auto-dispatch).
  Future<void> autoAssignNearest(String requestId) async {
    final requestRef =
        _firestore.collection(FirebaseCollections.requests).doc(requestId);
    final requestSnap = await requestRef.get();
    if (!requestSnap.exists) return;

    final request = RequestModel.fromMap(requestSnap.id, requestSnap.data()!);
    if (request.status != RequestStatus.pending) return;
    if (request.pickupLocation == null) return;

    final match = await findNearest(pickup: request.pickupLocation!);
    if (match == null) return;

    final driverSnap = await _drivers.doc(match.driverId).get();
    if (!driverSnap.exists) return;
    final data = driverSnap.data()!;

    await requestRef.update({
      'driverId': match.driverId,
      'driverName': data['name']?.toString() ?? '',
      'driverPhone': data['phone']?.toString() ?? '',
      'driverVehicle': data['vehicle']?.toString() ?? 'Moto',
      'driverPlate': data['plateNumber']?.toString() ?? '',
      'distanceKm': match.distanceKm,
      'durationMinutes': LocationService.etaMinutes(
        data['currentLocation'] as GeoPoint? ?? request.pickupLocation!,
        request.pickupLocation!,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
