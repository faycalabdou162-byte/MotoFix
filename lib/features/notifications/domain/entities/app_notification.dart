/// In-app notification entity (Firestore-backed, domain layer).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.createdAt,
    required this.read,
    this.requestId,
    this.type,
  });

  final String id;
  final String title;
  final String message;
  final String icon;
  final DateTime? createdAt;
  final bool read;
  final String? requestId;
  final String? type;
}
