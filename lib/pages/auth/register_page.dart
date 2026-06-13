import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  late final AuthService _authService;
  bool loading = false;
  bool accepted = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (loading) return;

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final password = passCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    if (name.length < 2 || email.isEmpty || phone.length < 6) {
      _showMessage('Veuillez completer vos informations.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Le mot de passe doit contenir au moins 6 caracteres.');
      return;
    }

    if (password != confirm) {
      _showMessage('Les mots de passe ne correspondent pas.');
      return;
    }

    if (!accepted) {
      _showMessage('Veuillez accepter les conditions.');
      return;
    }

    setState(() => loading = true);

    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authMessage(error.code));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Creation impossible: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _authMessage(String code) {
    return switch (code) {
      'email-already-in-use' => 'Cet email est deja utilise.',
      'invalid-email' => 'Email invalide.',
      'weak-password' => 'Mot de passe trop faible.',
      _ => 'Creation du compte impossible.',
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
      appBar: MotoFixUi.appBar('Creer un compte'),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  MotoFixField(
                    controller: nameCtrl,
                    hint: 'Nom complet',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  MotoFixField(
                    controller: emailCtrl,
                    hint: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  MotoFixField(
                    controller: phoneCtrl,
                    hint: 'Telephone',
                    icon: Icons.phone_iphone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  MotoFixField(
                    controller: passCtrl,
                    hint: 'Mot de passe',
                    icon: Icons.lock_outline,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  MotoFixField(
                    controller: confirmCtrl,
                    hint: 'Confirmer le mot de passe',
                    icon: Icons.lock_outline,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => register(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: accepted,
                          activeColor: MotoFixUi.orange,
                          side: const BorderSide(color: MotoFixUi.textSoft),
                          onChanged: loading
                              ? null
                              : (value) {
                                  setState(() => accepted = value ?? false);
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "J'accepte les ",
                            children: [
                              TextSpan(
                                text: "conditions d'utilisation",
                                style: TextStyle(color: MotoFixUi.orange),
                              ),
                            ],
                          ),
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  MotoFixButton(
                    label: 'Creer un compte',
                    loading: loading,
                    onPressed: loading ? null : register,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'Deja un compte ? ',
                        style: TextStyle(color: MotoFixUi.textSoft),
                      ),
                      GestureDetector(
                        onTap: loading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Se connecter',
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
