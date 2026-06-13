import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/motofix_ui.dart';
import '../services/notification_service.dart';
import 'request/request_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();
    final body = SafeArea(
      child: StreamBuilder<List<AppNotification>>(
        stream: service.watchRequestStatusNotifications(),
        builder: (context, requestSnapshot) {
          return StreamBuilder<List<AppNotification>>(
            stream: service.watchCurrentUserNotifications(),
            builder: (context, manualSnapshot) {
              return StreamBuilder<List<AppNotification>>(
                stream: service.watchPromotions(),
                builder: (context, promoSnapshot) {
                  final notifications = [
                    ...?requestSnapshot.data,
                    ...?manualSnapshot.data,
                    ...?promoSnapshot.data,
                  ];
                  notifications.sort((a, b) {
                    final aDate =
                        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bDate =
                        b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bDate.compareTo(aDate);
                  });

                  if (notifications.isEmpty) {
                    return const _EmptyNotifications();
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    children: [
                      for (final item in notifications)
                        _NotificationTile(notification: item),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (embedded) return body;
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Notifications'),
      child: body,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final date = notification.createdAt == null
        ? ''
        : DateFormat('dd MMM yyyy - HH:mm').format(notification.createdAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: notification.requestId == null || notification.requestId!.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestPage(requestId: notification.requestId),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _colorFor(notification.icon),
                child: Icon(_iconFor(notification.icon), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(color: MotoFixUi.textSoft),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: MotoFixUi.textSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MotoFixUi.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String icon) {
    return switch (icon) {
      'accepted' => Icons.verified_outlined,
      'route' => Icons.route_outlined,
      'arrived' => Icons.flag_outlined,
      'done' => Icons.check_circle_outline,
      'promotion' => Icons.local_offer_outlined,
      'taxi' => Icons.local_taxi,
      'repair' => Icons.build_circle_outlined,
      _ => Icons.notifications_none,
    };
  }

  Color _colorFor(String icon) {
    return switch (icon) {
      'promotion' => const Color(0xFF6A55C9),
      'done' || 'arrived' => MotoFixUi.green,
      'route' => Colors.blueAccent,
      _ => MotoFixUi.orange,
    };
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: MotoFixUi.panelDecoration(radius: 8),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, color: MotoFixUi.orange, size: 44),
              SizedBox(height: 12),
              Text(
                'Aucune notification',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Les alertes de course, paiements et promotions apparaitront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MotoFixUi.textSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
