import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/services/location_service.dart';
import '../../../../models/request_model.dart';

class TrackingFirebaseDataSource {
  TrackingFirebaseDataSource({
    FirebaseFirestore? firestore,
    LocationService? locationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _location = locationService ?? LocationService();

  final FirebaseFirestore _firestore;
  final LocationService _location;

  Stream<RequestModel?> watchRequest(String requestId) {
    return _firestore
        .collection(FirebaseCollections.requests)
        .doc(requestId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (!doc.exists || data == null) return null;
          return RequestModel.fromMap(doc.id, data);
        });
  }

  Future<GeoPoint?> currentUserLocation() => _location.currentGeoPoint();

  Stream<GeoPoint> watchUserLocation({int distanceFilterMeters = 15}) {
    return _location
        .positionStream(distanceFilterMeters: distanceFilterMeters)
        .map((p) => GeoPoint(p.latitude, p.longitude));
  }
}
