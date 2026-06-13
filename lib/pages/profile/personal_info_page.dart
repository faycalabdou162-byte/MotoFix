import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool loaded = false;
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _fillOnce(Map<String, dynamic>? data) {
    if (loaded) return;
    loaded = true;
    nameController.text = data?['name']?.toString() ?? '';
    phoneController.text = data?['phone']?.toString() ?? '';
    addressController.text = data?['defaultAddress']?.toString() ?? '';
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || saving) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    if (name.length < 2 || phone.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom ou telephone invalide.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': name,
        'phone': phone,
        'defaultAddress': address.isEmpty ? 'Niamey, Niger' : address,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis a jour')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise a jour impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Informations'),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid ?? '_')
              .snapshots(),
          builder: (context, snapshot) {
            _fillOnce(snapshot.data?.data());

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                MotoFixField(
                  controller: nameController,
                  hint: 'Nom complet',
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                MotoFixField(
                  controller: phoneController,
                  hint: 'Telephone',
                  icon: Icons.phone_iphone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                MotoFixField(
                  controller: addressController,
                  hint: 'Adresse par defaut',
                  icon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 22),
                MotoFixButton(
                  label: 'Enregistrer',
                  loading: saving,
                  icon: Icons.save_outlined,
                  onPressed: saving ? null : _save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
