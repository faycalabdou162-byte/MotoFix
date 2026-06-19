import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/notification_firebase_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    dataSource: NotificationFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
      auth: ref.watch(firebaseAuthProvider),
    ),
  );
});

final userNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchCurrentUserNotifications();
});

final requestNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(notificationRepositoryProvider)
      .watchRequestStatusNotifications();
});

final promotionNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchPromotions();
});
