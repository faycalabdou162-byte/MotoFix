import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/request_model.dart';

abstract class TrackingRepository {
  Stream<RequestModel?> watchRequestTracking(String requestId);

  Future<GeoPoint?> currentUserLocation();

  Stream<GeoPoint> watchUserLocation({int distanceFilterMeters});
}
