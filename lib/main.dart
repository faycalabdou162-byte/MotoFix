import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MotoFixApp());
}

class MotoFixApp extends StatelessWidget {
  const MotoFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'MotoFix Niger',

      theme: AppTheme.darkTheme,

      routes: AppRoutes.routes,

      home: const SplashPage(),
    );
  }
}
