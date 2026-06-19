import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/motofix_ui.dart';
import '../../../models/user_model.dart';
import '../../../pages/admin/admin_page.dart';
import '../../../pages/auth/login_page.dart';
import '../../../pages/driver/driver_dashboard_page.dart';
import '../../../pages/home/dashboard_page.dart';
import '../../../pages/maintenance_page.dart';
import '../../../services/app_config_service.dart';
import 'providers/auth_providers.dart';
/// Routes authenticated users by role; blocks suspended accounts.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const _GateLoading(),
      error: (error, _) => _GateMessage(
        title: 'Connexion incomplete',
        message: '$error',
      ),
      data: (user) {
        if (user == null) return const LoginPage();

        return _RoleRouter(uid: user.uid);
      },
    );
  }
}

class _RoleRouter extends ConsumerWidget {
  const _RoleRouter({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const _GateLoading(),
      error: (error, _) => _GateMessage(
        title: 'Profil introuvable',
        message: '$error',
      ),
      data: (profile) {
        if (profile == null) {
          return const _GateMessage(
            title: 'Profil introuvable',
            message: 'Votre compte existe mais le profil est incomplet.',
          );
        }

        if (profile.isSuspended) {
          return _GateMessage(
            title: 'Compte suspendu',
            message:
                'Votre compte a ete suspendu. Contactez le support MotoFix.',
            action: TextButton(
              onPressed: () =>
                  ref.read(authRepositoryProvider).logout(),
              child: const Text('Se deconnecter'),
            ),
          );
        }

        if (profile.role == UserRole.admin) {
          return const AdminPage();
        }
        if (profile.role == UserRole.driver) {
          return const DriverDashboardPage();
        }
        return const DashboardPage();
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
  const _GateMessage({
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

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
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Splash routing helper — maintenance check before auth gate.
Future<Widget> resolvePostSplashDestination() async {
  try {
    final config = await AppConfigService().fetchMaintenanceConfig();
    if (config.blocksApp) {
      return MaintenancePage(config: config);
    }
  } catch (_) {
    // config read failed — continue to auth
  }
  return const AuthGate();
}
