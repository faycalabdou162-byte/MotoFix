import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../models/feature_models.dart';
import '../../../../models/user_model.dart';

class ChatFirebaseDataSource {
  ChatFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

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
        .map((snapshot) => snapshot.docs.map(ChatMessageModel.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String requestId,
    required String type,
    required String text,
    GeoPoint? location,
    String photoUrl = '',
    String voiceUrl = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecte');

    final userDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();
    final data = userDoc.data() ?? const <String, dynamic>{};
    final name = data['name']?.toString().trim();
    final role = UserRole.normalize(data['role']?.toString());

    await _messages(requestId).add({
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

  Future<GeoPoint> currentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
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

    return GeoPoint(position.latitude, position.longitude);
  }

  Future<String> uploadImage({
    required String requestId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecte');

    final path =
        'chat/$requestId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child(path);
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
