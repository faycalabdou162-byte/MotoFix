import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/request/data/datasources/request_firebase_datasource.dart';
import '../features/request/data/repositories/request_repository_impl.dart';

export '../features/request/domain/repositories/request_repository.dart'
    show RequestRepository;

/// Backward-compatible facade — prefer [RequestRepository] via Riverpod.
class RequestService extends RequestRepositoryImpl {
  RequestService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : super(
          dataSource: RequestFirebaseDataSource(
            firestore: firestore,
            auth: auth,
          ),
        );
}
