import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../services/safety_service.dart';

class SafetyCenterPage extends StatefulWidget {
  const SafetyCenterPage({super.key});

  @override
  State<SafetyCenterPage> createState() => _SafetyCenterPageState();
}

class _SafetyCenterPageState extends State<SafetyCenterPage> {
  final SafetyService _safetyService = SafetyService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _sendSos() async {
    if (loading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Envoyer un SOS ?'),
          content: const Text(
            'MotoFix recevra votre position si elle est disponible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Envoyer SOS'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => loading = true);
    try {
      await _safetyService.sendSos();
      _showMessage('SOS envoye au centre MotoFix');
    } catch (error) {
      _showMessage('SOS impossible: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.length < 2 || phone.length < 6) {
      _showMessage('Contact incomplet.');
      return;
    }

    await _safetyService.addEmergencyContact(name: name, phone: phone);
    _nameController.clear();
    _phoneController.clear();
  }

  Future<void> _sendReport() async {
    final message = _reportController.text.trim();
    if (message.length < 8) {
      _showMessage('Ajoutez un signalement plus detaille.');
      return;
    }

    setState(() => loading = true);
    try {
      await _safetyService.sendSignalement(message: message);
      _reportController.clear();
      _showMessage('Signalement envoye');
    } catch (error) {
      _showMessage('Signalement impossible: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Centre de Securite'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SizedBox(
              height: 62,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: loading ? null : _sendSos,
                icon: const Icon(Icons.sos),
                label: const Text(
                  'Bouton SOS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Contacts d urgence'),
            MotoFixField(
              controller: _nameController,
              hint: 'Nom du contact',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            MotoFixField(
              controller: _phoneController,
              hint: 'Telephone',
              icon: Icons.phone_iphone,
              keyboardType: TextInputType.phone,
              onSubmitted: (_) => _addContact(),
            ),
            const SizedBox(height: 10),
            MotoFixButton(
              label: 'Ajouter le contact',
              icon: Icons.person_add_alt,
              onPressed: _addContact,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _safetyService.watchEmergencyContacts(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _SafetyMessage('Aucun contact enregistre.');
                }

                return Column(
                  children: [
                    for (final doc in docs)
                      _ContactTile(
                        data: doc.data(),
                        onDelete: () {
                          _safetyService.deleteEmergencyContact(doc.id);
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Signalement'),
            MotoFixField(
              controller: _reportController,
              hint: 'Expliquez le probleme ou le danger',
              minLines: 4,
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            MotoFixButton(
              label: 'Envoyer le signalement',
              loading: loading,
              icon: Icons.report_outlined,
              onPressed: loading ? null : _sendReport,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.data, required this.onDelete});

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
          const Icon(Icons.contact_phone_outlined, color: MotoFixUi.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name']?.toString() ?? 'Contact',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data['phone']?.toString() ?? '',
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

class _SafetyMessage extends StatelessWidget {
  const _SafetyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: MotoFixUi.textSoft),
      ),
    );
  }
}
