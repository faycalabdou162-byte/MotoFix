import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/request_model.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_firebase_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl({TrackingFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? TrackingFirebaseDataSource();

  final TrackingFirebaseDataSource _dataSource;

  @override
  Stream<RequestModel?> watchRequestTracking(String requestId) {
    return _dataSource.watchRequest(requestId);
  }

  @override
  Future<GeoPoint?> currentUserLocation() {
    return _dataSource.currentUserLocation();
  }

  @override
  Stream<GeoPoint> watchUserLocation({int distanceFilterMeters = 15}) {
    return _dataSource.watchUserLocation(
      distanceFilterMeters: distanceFilterMeters,
    );
  }
}
