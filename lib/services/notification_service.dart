import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_collections.dart';
import '../models/request_model.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.createdAt,
    required this.read,
    this.requestId,
  });

  final String id;
  final String title;
  final String message;
  final String icon;
  final DateTime? createdAt;
  final bool read;
  final String? requestId;
}

class NotificationService {
  NotificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _userNotifications(String uid) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .collection(FirebaseCollections.notifications);
  }

  Stream<List<AppNotification>> watchCurrentUserNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    final manual = _userNotifications(uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_fromNotificationDoc).toList();
        });

    return manual;
  }

  Stream<List<AppNotification>> watchRequestStatusNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _firestore
        .collection(FirebaseCollections.requests)
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _fromRequestDoc(doc.id, doc.data()))
              .whereType<AppNotification>()
              .toList();
        });
  }

  Stream<List<AppNotification>> watchPromotions() {
    return _firestore
        .collection(FirebaseCollections.promotions)
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return AppNotification(
              id: doc.id,
              title: data['title']?.toString() ?? 'Promotion',
              message: data['message']?.toString() ?? '',
              icon: 'promotion',
              createdAt: _dateFromValue(data['createdAt']),
              read: false,
            );
          }).toList();
        });
  }

  Future<void> createForCurrentUser({
    required String title,
    required String message,
    String icon = 'info',
    String requestId = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _userNotifications(uid).add({
      'title': title.trim(),
      'message': message.trim(),
      'icon': icon,
      'requestId': requestId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _userNotifications(uid).doc(notificationId).update({
      'read': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  AppNotification _fromNotificationDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      title: data['title']?.toString() ?? 'Notification',
      message: data['message']?.toString() ?? '',
      icon: data['icon']?.toString() ?? 'info',
      createdAt: _dateFromValue(data['createdAt']),
      read: data['read'] as bool? ?? false,
      requestId: data['requestId']?.toString(),
    );
  }

  AppNotification? _fromRequestDoc(String id, Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? RequestType.taxi;
    final service = RequestType.label(type);
    final status = data['status']?.toString() ?? RequestStatus.pending;
    final driverName = data['driverName']?.toString() ?? '';

    return switch (status) {
      RequestStatus.accepted => AppNotification(
        id: '$id-accepted',
        title: 'Nouvel appel accepte',
        message: driverName.isEmpty
            ? '$service: chauffeur affecte.'
            : '$driverName a accepte votre demande.',
        icon: 'accepted',
        createdAt: _dateFromValue(data['updatedAt']),
        read: false,
        requestId: id,
      ),
      RequestStatus.inProgress => AppNotification(
        id: '$id-route',
        title: 'Chauffeur en route',
        message: '$service: le chauffeur se rapproche de vous.',
        icon: 'route',
        createdAt: _dateFromValue(data['updatedAt']),
        read: false,
        requestId: id,
      ),
      RequestStatus.arrived => AppNotification(
        id: '$id-arrived',
        title: 'Chauffeur arrive',
        message: '$service: le chauffeur est arrive au point de depart.',
        icon: 'arrived',
        createdAt: _dateFromValue(data['updatedAt']),
        read: false,
        requestId: id,
      ),
      RequestStatus.completed => AppNotification(
        id: '$id-completed',
        title: 'Course terminee',
        message: '$service: merci d utiliser MotoFix Niger.',
        icon: 'done',
        createdAt: _dateFromValue(data['updatedAt']),
        read: false,
        requestId: id,
      ),
      _ => null,
    };
  }
}

DateTime? _dateFromValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
