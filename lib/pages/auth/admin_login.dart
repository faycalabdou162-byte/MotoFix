import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final email = TextEditingController();
  final password = TextEditingController();

  late final AuthService _authService;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> loginAdmin() async {
    if (loading) return;

    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      _showMessage('Veuillez entrer email et mot de passe.');
      return;
    }

    setState(() => loading = true);

    try {
      final cred = await _authService.login(email.text, password.text);
      final uid = cred.user?.uid;
      if (uid == null) {
        throw StateError('Compte introuvable');
      }

      final role = await _authService.getUserRole(uid);
      if (role != UserRole.admin) {
        await _authService.logout();
        if (!mounted) return;
        _showMessage('Acces refuse.');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage('Erreur: ${error.message ?? error.code}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Connexion admin impossible: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Connexion Admin'),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: MotoFixUi.orange,
                    size: 66,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Espace administrateur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  MotoFixField(
                    controller: email,
                    hint: 'Email admin',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  MotoFixField(
                    controller: password,
                    hint: 'Mot de passe',
                    icon: Icons.lock_outline,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => loginAdmin(),
                  ),
                  const SizedBox(height: 22),
                  MotoFixButton(
                    label: 'Connexion Admin',
                    loading: loading,
                    icon: Icons.login,
                    onPressed: loading ? null : loginAdmin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
