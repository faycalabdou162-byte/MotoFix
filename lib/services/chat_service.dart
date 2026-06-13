import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/firebase_collections.dart';
import '../models/feature_models.dart';
import '../models/user_model.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _messages(String requestId) {
    return _firestore
        .collection(FirebaseCollections.requests)
        .doc(requestId)
        .collection(FirebaseCollections.messages);
  }

  Stream<List<ChatMessageModel>> watchMessages(String requestId) {
    return _messages(requestId)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(ChatMessageModel.fromDoc).toList();
        });
  }

  Future<void> sendText({
    required String requestId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    await _send(
      requestId: requestId,
      type: ChatMessageType.text,
      text: cleanText,
    );
  }

  Future<void> sendCurrentLocation(String requestId) async {
    final locationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationEnabled) {
      throw StateError('Activez la localisation du telephone');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Permission de localisation refusee');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    await _send(
      requestId: requestId,
      type: ChatMessageType.location,
      text: 'Position partagee',
      location: GeoPoint(position.latitude, position.longitude),
    );
  }

  Future<void> sendPhotoReference({
    required String requestId,
    required String photoUrl,
    String caption = '',
  }) {
    return _send(
      requestId: requestId,
      type: ChatMessageType.photo,
      text: caption.trim().isEmpty ? 'Photo de panne' : caption.trim(),
      photoUrl: photoUrl.trim(),
    );
  }

  Future<void> sendVoiceReference({
    required String requestId,
    required String voiceUrl,
    String label = 'Message vocal',
  }) {
    return _send(
      requestId: requestId,
      type: ChatMessageType.voice,
      text: label.trim().isEmpty ? 'Message vocal' : label.trim(),
      voiceUrl: voiceUrl.trim(),
    );
  }

  Future<void> _send({
    required String requestId,
    required String type,
    required String text,
    GeoPoint? location,
    String photoUrl = '',
    String voiceUrl = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecte');
    }

    final userDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();
    final data = userDoc.data() ?? const <String, dynamic>{};
    final name = data['name']?.toString().trim();
    final role = UserRole.normalize(data['role']?.toString());

    await _messages(requestId).add({
      'requestId': requestId,
      'senderId': user.uid,
      'senderName': name?.isNotEmpty == true
          ? name
          : user.displayName ?? 'MotoFix',
      'senderRole': role,
      'type': type,
      'text': text,
      'location': location,
      'photoUrl': photoUrl,
      'voiceUrl': voiceUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
