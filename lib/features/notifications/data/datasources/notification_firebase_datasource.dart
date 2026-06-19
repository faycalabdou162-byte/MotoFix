import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../models/request_model.dart';
import '../../domain/entities/app_notification.dart';

class NotificationFirebaseDataSource {
  NotificationFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _userNotifications(String uid) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .collection(FirebaseCollections.notifications);
  }

  Stream<List<AppNotification>> watchUserNotifications(String uid) {
    return _userNotifications(uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  Stream<List<AppNotification>> watchRequestDerived(String uid) {
    return _firestore
        .collection(FirebaseCollections.requests)
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) {
          return s.docs
              .map((d) => _fromRequest(d.id, d.data()))
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
        .map((s) {
          return s.docs.map((doc) {
            final data = doc.data();
            return AppNotification(
              id: doc.id,
              title: data['title']?.toString() ?? 'Promotion',
              message: data['message']?.toString() ?? '',
              icon: 'promotion',
              createdAt: _date(data['createdAt']),
              read: false,
              type: 'promotion',
            );
          }).toList();
        });
  }

  Future<void> create(String uid, {
    required String title,
    required String message,
    String icon = 'info',
    String requestId = '',
  }) {
    return _userNotifications(uid).add({
      'title': title.trim(),
      'message': message.trim(),
      'icon': icon,
      'requestId': requestId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String uid, String notificationId) {
    return _userNotifications(uid).doc(notificationId).update({
      'read': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      title: data['title']?.toString() ?? 'Notification',
      message: data['message']?.toString() ?? '',
      icon: data['icon']?.toString() ?? 'info',
      createdAt: _date(data['createdAt']),
      read: data['read'] as bool? ?? false,
      requestId: data['requestId']?.toString(),
      type: data['type']?.toString(),
    );
  }

  AppNotification? _fromRequest(String id, Map<String, dynamic> data) {
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
        createdAt: _date(data['updatedAt']),
        read: false,
        requestId: id,
        type: 'request_accepted',
      ),
      RequestStatus.inProgress => AppNotification(
        id: '$id-route',
        title: 'Chauffeur en route',
        message: '$service: le chauffeur se rapproche de vous.',
        icon: 'route',
        createdAt: _date(data['updatedAt']),
        read: false,
        requestId: id,
        type: 'ride_started',
      ),
      RequestStatus.arrived => AppNotification(
        id: '$id-arrived',
        title: 'Chauffeur arrive',
        message: '$service: le chauffeur est arrive au point de depart.',
        icon: 'arrived',
        createdAt: _date(data['updatedAt']),
        read: false,
        requestId: id,
        type: 'ride_arrived',
      ),
      RequestStatus.completed => AppNotification(
        id: '$id-completed',
        title: 'Course terminee',
        message: '$service: merci d utiliser MotoFix Niger.',
        icon: 'done',
        createdAt: _date(data['updatedAt']),
        read: false,
        requestId: id,
        type: 'ride_completed',
      ),
      _ => null,
    };
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
