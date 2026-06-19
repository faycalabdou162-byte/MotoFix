import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_firebase_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({NotificationFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? NotificationFirebaseDataSource();

  final NotificationFirebaseDataSource _dataSource;

  String? get _uid => _dataSource.currentUid;

  @override
  Stream<List<AppNotification>> watchCurrentUserNotifications() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _dataSource.watchUserNotifications(uid);
  }

  @override
  Stream<List<AppNotification>> watchRequestStatusNotifications() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _dataSource.watchRequestDerived(uid);
  }

  @override
  Stream<List<AppNotification>> watchPromotions() {
    return _dataSource.watchPromotions();
  }

  @override
  Future<void> createForCurrentUser({
    required String title,
    required String message,
    String icon = 'info',
    String requestId = '',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _dataSource.create(
      uid,
      title: title,
      message: message,
      icon: icon,
      requestId: requestId,
    );
  }

  @override
  Future<void> markRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;
    await _dataSource.markRead(uid, notificationId);
  }
}
