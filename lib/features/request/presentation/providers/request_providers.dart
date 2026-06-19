import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../models/request_model.dart';
import '../../data/datasources/request_firebase_datasource.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../domain/repositories/request_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepositoryImpl(
    dataSource: RequestFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
      auth: ref.watch(firebaseAuthProvider),
    ),
  );
});

final userRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(requestRepositoryProvider).watchUserRequests(user.uid);
});

/// Alias standard — stream d'une demande par id.
final requestStreamProvider =
    StreamProvider.family<RequestModel?, String>((ref, requestId) {
  return ref.watch(requestRepositoryProvider).watchRequest(requestId);
});

final requestByIdProvider = requestStreamProvider;
