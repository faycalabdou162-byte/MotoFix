import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/data/datasources/auth_firebase_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';

export '../features/auth/domain/repositories/auth_repository.dart'
    show AuthRepository;

/// Backward-compatible facade — prefer [AuthRepository] via Riverpod.
class AuthService extends AuthRepositoryImpl {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : super(
          dataSource: AuthFirebaseDataSource(
            auth: auth,
            firestore: firestore,
          ),
        );
}
