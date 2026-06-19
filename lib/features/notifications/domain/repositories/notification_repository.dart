import '../../domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchCurrentUserNotifications();

  Stream<List<AppNotification>> watchRequestStatusNotifications();

  Stream<List<AppNotification>> watchPromotions();

  Future<void> createForCurrentUser({
    required String title,
    required String message,
    String icon,
    String requestId,
  });

  Future<void> markRead(String notificationId);
}
