import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final labelController = TextEditingController();
  final addressController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    labelController.dispose();
    addressController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>? _addresses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses');
  }

  Future<void> _addAddress() async {
    final addresses = _addresses();
    if (addresses == null || saving) return;

    final label = labelController.text.trim();
    final address = addressController.text.trim();

    if (label.length < 2 || address.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse incomplete.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await addresses.add({
        'label': label,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      labelController.clear();
      addressController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ajout impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    final addresses = _addresses();
    if (addresses == null) return;
    await addresses.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final addresses = _addresses();

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Mes adresses'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            MotoFixField(
              controller: labelController,
              hint: 'Nom de l adresse',
              icon: Icons.bookmark_outline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            MotoFixField(
              controller: addressController,
              hint: 'Adresse ou repere',
              icon: Icons.location_on_outlined,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addAddress(),
            ),
            const SizedBox(height: 14),
            MotoFixButton(
              label: 'Ajouter une adresse',
              loading: saving,
              icon: Icons.add_location_alt_outlined,
              onPressed: saving ? null : _addAddress,
            ),
            const SizedBox(height: 22),
            const Text(
              'Adresses enregistrees',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (addresses == null)
              const _EmptyAddresses()
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: addresses.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: MotoFixUi.orange,
                        ),
                      ),
                    );
                  }

                  if (docs.isEmpty) return const _EmptyAddresses();

                  return Column(
                    children: [
                      for (final doc in docs)
                        _AddressTile(
                          data: doc.data(),
                          onDelete: () => _deleteAddress(doc.id),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.data,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: MotoFixUi.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['label']?.toString() ?? 'Adresse',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data['address']?.toString() ?? '',
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: const Text(
        'Aucune adresse enregistree.',
        textAlign: TextAlign.center,
        style: TextStyle(color: MotoFixUi.textSoft),
      ),
    );
  }
}
