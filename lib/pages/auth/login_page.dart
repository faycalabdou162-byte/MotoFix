import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth_gate.dart';
import '../../core/theme/motofix_ui.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AuthService _authService;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.login(email, password);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authMessage(error.code));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Connexion impossible: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Entrez votre email avant la reinitialisation.');
      return;
    }

    try {
      await _authService.sendPasswordReset(email);
      if (!mounted) return;
      _showMessage('Email de reinitialisation envoye.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authMessage(error.code));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Operation impossible: $error');
    }
  }

  String _authMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Email invalide.',
      'user-disabled' => 'Ce compte est desactive.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email ou mot de passe incorrect.',
      _ => 'Erreur de connexion.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 34),
                  CustomTextField(
                    controller: _emailController,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hint: 'Mot de passe',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text(
                        'Mot de passe oublie ?',
                        style: TextStyle(
                          color: MotoFixUi.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _loading
                      ? const MotoFixButton(
                          label: 'Se connecter',
                          loading: true,
                          onPressed: null,
                        )
                      : CustomButton(
                          text: 'Se connecter',
                          onPressed: _login,
                        ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(color: MotoFixUi.textSoft),
                      ),
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Creer un compte',
                          style: TextStyle(
                            color: MotoFixUi.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
