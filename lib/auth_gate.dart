import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/theme/motofix_ui.dart';
import 'models/user_model.dart';
import 'pages/admin/admin_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/driver/driver_dashboard_page.dart';
import 'pages/home/dashboard_page.dart';
import 'services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();

    return StreamBuilder<User?>(
      stream: service.authState,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoading();
        }

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<String>(
          future: service.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _GateLoading();
            }

            if (roleSnapshot.hasError) {
              return _GateMessage(
                title: 'Connexion incomplete',
                message: '${roleSnapshot.error}',
              );
            }

            final role = roleSnapshot.data ?? UserRole.client;
            if (role == UserRole.admin) {
              return const AdminPage();
            }

            if (role == UserRole.driver) {
              return const DriverDashboardPage();
            }

            return const DashboardPage();
          },
        );
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      child: const Center(
        child: CircularProgressIndicator(color: MotoFixUi.orange),
      ),
    );
  }
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: MotoFixUi.orange,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MotoFixUi.textSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
