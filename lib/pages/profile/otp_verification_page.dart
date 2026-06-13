import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String verificationId = '';
  bool codeSent = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8 || loading) {
      _showMessage('Numero invalide. Utilisez le format international.');
      return;
    }

    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          await _completeVerification(credential, phone);
        },
        verificationFailed: (error) {
          _showMessage('OTP impossible: ${error.message ?? error.code}');
          if (mounted) setState(() => loading = false);
        },
        codeSent: (id, _) {
          if (!mounted) return;
          setState(() {
            verificationId = id;
            codeSent = true;
            loading = false;
          });
          _showMessage('Code envoye par SMS');
        },
        codeAutoRetrievalTimeout: (id) {
          verificationId = id;
        },
      );
    } catch (error) {
      _showMessage('Envoi OTP impossible: $error');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (verificationId.isEmpty || code.length < 4 || loading) return;

    setState(() => loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await _completeVerification(credential, _phoneController.text.trim());
    } catch (error) {
      _showMessage('Code invalide: $error');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _completeVerification(
    PhoneAuthCredential credential,
    String phone,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Utilisateur non connecte');

    await user.updatePhoneNumber(credential);
    await user.getIdToken(true);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'phone': phone,
      'phoneVerified': true,
      'phoneVerifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => loading = false);
    _showMessage('Numero valide');
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Verification OTP'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MotoFixUi.panelDecoration(radius: 8),
              child: const Row(
                children: [
                  Icon(Icons.sms_outlined, color: MotoFixUi.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Firebase enverra un SMS pour valider votre numero.',
                      style: TextStyle(color: MotoFixUi.textSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            MotoFixField(
              controller: _phoneController,
              hint: 'Numero avec indicatif (+227...)',
              icon: Icons.phone_iphone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 14),
            MotoFixButton(
              label: codeSent ? 'Renvoyer le code' : 'Envoyer le SMS',
              loading: loading && !codeSent,
              icon: Icons.sms_outlined,
              onPressed: loading ? null : _sendCode,
            ),
            if (codeSent) ...[
              const SizedBox(height: 18),
              MotoFixField(
                controller: _codeController,
                hint: 'Code OTP',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 14),
              MotoFixButton(
                label: 'Valider le numero',
                loading: loading,
                icon: Icons.verified_outlined,
                onPressed: loading ? null : _verifyCode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
