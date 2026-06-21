import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/shell/presentation/shell_page.dart';
import '../../features/splash/presentation/splash_page.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const shell = '/shell';
}

abstract class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.shell:
        return MaterialPageRoute(builder: (_) => const ShellPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Not Found'))),
        );
    }
  }
}

