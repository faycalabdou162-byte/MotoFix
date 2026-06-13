import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../services/auth_service.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool loading = false;

  Future<void> _sendReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || loading) return;

    setState(() => loading = true);

    try {
      await AuthService().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de securite envoye')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Securite'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MotoFixUi.panelDecoration(radius: 8),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: MotoFixUi.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gardez votre compte protege. Le changement de mot de passe passe par un email securise Firebase.',
                      style: TextStyle(color: MotoFixUi.textSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            MotoFixButton(
              label: 'Changer le mot de passe',
              loading: loading,
              icon: Icons.mark_email_read_outlined,
              onPressed: loading ? null : _sendReset,
            ),
          ],
        ),
      ),
    );
  }
}
