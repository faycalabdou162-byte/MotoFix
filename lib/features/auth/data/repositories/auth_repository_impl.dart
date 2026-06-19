import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_firebase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? AuthFirebaseDataSource();

  final AuthFirebaseDataSource _dataSource;

  @override
  Stream<User?> get authState => _dataSource.authStateChanges();

  @override
  Future<UserCredential> login(String email, String password) {
    return _dataSource.signInWithEmail(email, password);
  }

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) {
    return _dataSource.createAccount(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
  }

  @override
  Future<UserModel?> getUserData(String uid) {
    return _dataSource.fetchUserProfile(uid);
  }

  @override
  Future<String> getUserRole(String uid) async {
    final user = await getUserData(uid);
    return user?.role ?? UserRole.client;
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> logout() => _dataSource.signOut();
}
