import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  runApp(const ProviderScope(child: RiderApp()));
}

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AppShell(
            title: 'Urban Mobility Rider',
            child: Center(
              child: Text('Book ride, track live trip, pay, review history'),
            ),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Urban Mobility Rider',
      theme: BrandTheme.dark(),
      routerConfig: router,
    );
  }
}
