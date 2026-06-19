import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/notifications/data/datasources/notification_firebase_datasource.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/domain/entities/app_notification.dart';
import '../features/notifications/domain/repositories/notification_repository.dart';

export '../features/notifications/domain/entities/app_notification.dart'
    show AppNotification;
export '../features/notifications/domain/repositories/notification_repository.dart'
    show NotificationRepository;

/// Backward-compatible facade — prefer [notificationRepositoryProvider].
class NotificationService extends NotificationRepositoryImpl {
  NotificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : super(
          dataSource: NotificationFirebaseDataSource(
            firestore: firestore,
            auth: auth,
          ),
        );
}
