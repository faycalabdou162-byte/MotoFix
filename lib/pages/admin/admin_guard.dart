import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'admin_page.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();

    return StreamBuilder<User?>(
      stream: service.authState,
      builder: (context, authSnap) {
        final user = authSnap.data;

        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _AdminGuardLoading();
        }

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<String>(
          future: service.getUserRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const _AdminGuardLoading();
            }

            if (roleSnap.data != UserRole.admin) {
              return const _AccessDenied();
            }

            return const AdminPage();
          },
        );
      },
    );
  }
}

class _AdminGuardLoading extends StatelessWidget {
  const _AdminGuardLoading();

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      child: const Center(
        child: CircularProgressIndicator(color: MotoFixUi.orange),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

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
                Icons.lock_outline,
                color: MotoFixUi.orange,
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                'Acces refuse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce compte ne possede pas les droits administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MotoFixUi.textSoft),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Changer de compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
