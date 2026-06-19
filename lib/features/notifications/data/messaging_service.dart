import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';

/// FCM pro — topics, token sync, foreground/background/deep-link handlers.
class MessagingService {
  MessagingService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  GlobalKey<NavigatorState>? _navigatorKey;
  Future<void> Function(String uid, String token)? _saveToken;

  void configure({
    required Future<void> Function(String uid, String token) saveToken,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    _saveToken = saveToken;
    _navigatorKey = navigatorKey;
  }

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _syncToken();
    _messaging.onTokenRefresh.listen((_) => _syncToken());

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _routeFromMessage(initial);
  }

  Future<void> subscribeUserTopics(String uid, {bool isDriver = false}) async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic('user_$uid');
    if (isDriver) await _messaging.subscribeToTopic('drivers');
    await _syncToken();
  }

  Future<void> _syncToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid != null && _saveToken != null) {
      await _saveToken!(uid, token);
    }

    await _messaging.subscribeToTopic('motofix_niger');
    debugPrint('FCM token synced for ${uid ?? 'anonymous'}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
  }

  void _onMessageOpened(RemoteMessage message) => _routeFromMessage(message);

  void _routeFromMessage(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    final requestId = message.data['requestId']?.toString() ?? '';
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    switch (type) {
      case 'request_accepted':
      case 'mechanic_assigned':
      case 'ride_started':
        if (requestId.isNotEmpty) {
          navigator.pushNamed('/request', arguments: requestId);
        }
      case 'chat_message':
        if (requestId.isNotEmpty) {
          navigator.pushNamed('/chat', arguments: requestId);
        }
      case 'payment_success':
        navigator.pushNamed('/payments');
      default:
        navigator.pushNamed('/home');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background: ${message.messageId}');
}

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    messaging: ref.watch(firebaseMessagingProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

Future<void> bootstrapMessaging(
  WidgetRef ref,
  GlobalKey<NavigatorState> navKey,
) async {
  final service = ref.read(messagingServiceProvider);
  final profileRepo = ref.read(profileRepositoryProvider);
  service.configure(
    navigatorKey: navKey,
    saveToken: (uid, token) =>
        profileRepo.saveFcmToken(uid: uid, token: token),
  );
  await service.initialize();

  ref.listen(authStateProvider, (previous, next) async {
    final user = next.value;
    if (user == null) return;
    final profile =
        await ref.read(authRepositoryProvider).getUserData(user.uid);
    await service.subscribeUserTopics(
      user.uid,
      isDriver: profile?.role == 'driver',
    );
  });
}
