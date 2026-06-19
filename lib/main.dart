import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/config/routes.dart';
import 'core/di/providers.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/data/messaging_service.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MotoFixApp()));
}

class MotoFixApp extends ConsumerStatefulWidget {
  const MotoFixApp({super.key});

  @override
  ConsumerState<MotoFixApp> createState() => _MotoFixAppState();
}

class _MotoFixAppState extends ConsumerState<MotoFixApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navKey = ref.read(rootNavigatorKeyProvider);
      await bootstrapMessaging(ref, navKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final navKey = ref.watch(rootNavigatorKeyProvider);

    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      title: 'MotoFix Niger',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routes: AppRoutes.routes,
      home: const SplashPage(),
    );
  }
}
