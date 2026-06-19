import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/user_model.dart';

/// Contract for authentication and user profile access.
abstract class AuthRepository {
  Stream<User?> get authState;

  Future<UserCredential> login(String email, String password);

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  });

  Future<UserModel?> getUserData(String uid);

  Future<String> getUserRole(String uid);

  Future<void> sendPasswordReset(String email);

  Future<void> logout();
}
