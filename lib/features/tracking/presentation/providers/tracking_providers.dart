import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../models/request_model.dart';
import '../../data/datasources/tracking_firebase_datasource.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/repositories/tracking_repository.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(
    dataSource: TrackingFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
    ),
  );
});

final requestTrackingProvider =
    StreamProvider.family<RequestModel?, String>((ref, requestId) {
  return ref.watch(trackingRepositoryProvider).watchRequestTracking(requestId);
});
