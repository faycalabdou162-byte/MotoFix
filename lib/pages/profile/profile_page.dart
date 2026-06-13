import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/user_model.dart';
import '../auth/login_page.dart';
import '../payment_page.dart';
import 'addresses_page.dart';
import 'personal_info_page.dart';
import 'security_page.dart';
import 'settings_page.dart';
import 'support_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream(),
        builder: (context, snapshot) {
          final user = FirebaseAuth.instance.currentUser;
          final data = snapshot.data?.data();
          final profile = data == null
              ? null
              : UserModel.fromMap({...data, 'uid': user?.uid ?? ''});
          final displayName =
              profile?.name.isNotEmpty == true ? profile!.name : 'Utilisateur';
          final email = profile?.email.isNotEmpty == true
              ? profile!.email
              : user?.email ?? '';
          final phone = profile?.phone ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                _ProfileHeader(
                  name: displayName,
                  email: email,
                  phone: phone,
                ),
                const SizedBox(height: 22),
                _ProfileAction(
                  icon: Icons.person_outline,
                  title: 'Informations personnelles',
                  onTap: () => _open(context, const PersonalInfoPage()),
                ),
                _ProfileAction(
                  icon: Icons.payments_outlined,
                  title: 'Mes paiements',
                  onTap: () => _open(context, const PaymentPage()),
                ),
                _ProfileAction(
                  icon: Icons.location_on_outlined,
                  title: 'Mes adresses',
                  onTap: () => _open(context, const AddressesPage()),
                ),
                _ProfileAction(
                  icon: Icons.security_outlined,
                  title: 'Securite',
                  onTap: () => _open(context, const SecurityPage()),
                ),
                _ProfileAction(
                  icon: Icons.settings_outlined,
                  title: 'Parametres',
                  onTap: () => _open(context, const SettingsPage()),
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.support_agent,
                  title: 'Aide & Support',
                  onTap: () => _open(context, const SupportPage()),
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.logout,
                  title: 'Deconnexion',
                  danger: true,
                  onTap: () => logout(context),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (embedded) return body;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Mon Profil'),
      child: body,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid ?? '_')
        .snapshots();
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.phone,
  });

  final String name;
  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MotoFixUi.orange, width: 4),
          ),
          child: CircleAvatar(
            backgroundColor: MotoFixUi.panel2,
            child: Text(
              initial,
              style: const TextStyle(
                color: MotoFixUi.orange,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        if (phone.isNotEmpty)
          Text(
            phone,
            style: const TextStyle(color: MotoFixUi.textSoft),
          ),
        if (email.isNotEmpty)
          Text(
            email,
            style: const TextStyle(color: MotoFixUi.textSoft),
          ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: MotoFixUi.panel,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: .7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
