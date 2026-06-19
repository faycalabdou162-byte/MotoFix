import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/theme_service.dart';
import '../../core/theme/motofix_ui.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool saving = false;

  Future<void> _updateNotifications(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || saving) return;

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'notificationsEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Parametres'),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid ?? '_')
              .snapshots(),
          builder: (context, snapshot) {
            final enabled =
                snapshot.data?.data()?['notificationsEnabled'] as bool? ?? true;
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) ==
                        Brightness.dark);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode sombre',
                  subtitle: isDark ? 'Activé' : 'Désactivé',
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Recevoir les alertes MotoFix',
                  trailing: Switch(
                    value: enabled,
                    activeThumbColor: MotoFixUi.orange,
                    onChanged: saving ? null : _updateNotifications,
                  ),
                ),
                const _SettingsTile(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: 'Francais',
                ),
                const _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'A propos',
                  subtitle: 'MotoFix Niger v1.0',
                ),
                const _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Confidentialite',
                  subtitle: 'Donnees protegees par Firestore Rules',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(icon, color: MotoFixUi.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
