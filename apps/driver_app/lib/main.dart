import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  runApp(const ProviderScope(child: DriverApp()));
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AppShell(
            title: 'Urban Mobility Driver',
            child: Center(
              child: Text('Go online, accept jobs, navigate, earn, reposition'),
            ),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Urban Mobility Driver',
      theme: BrandTheme.dark(),
      routerConfig: router,
    );
  }
}
