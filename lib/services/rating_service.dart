import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_collections.dart';

class RatingService {
  RatingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> rateDriver({
    required String requestId,
    required String driverId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecte');
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Note invalide');
    }

    await _firestore.collection(FirebaseCollections.ratings).doc(requestId).set({
      'requestId': requestId,
      'driverId': driverId,
      'userId': user.uid,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
