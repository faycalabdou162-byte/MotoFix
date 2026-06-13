import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) return credential;

    await user.updateDisplayName(cleanName);

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': cleanName,
      'email': cleanEmail,
      'phone': cleanPhone,
      'role': UserRole.client,
      'status': UserStatus.active,
      'notificationsEnabled': true,
      'language': 'fr',
      'darkMode': true,
      'phoneVerified': false,
      'defaultAddress': 'Niamey, Niger',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;

      return UserModel.fromMap({...data, 'uid': uid});
    } catch (error, stackTrace) {
      debugPrint('AuthService.getUserData failed: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<String> getUserRole(String uid) async {
    final user = await getUserData(uid);
    return user?.role ?? UserRole.client;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> logout() => _auth.signOut();

  Stream<User?> get authState => _auth.authStateChanges();
}
