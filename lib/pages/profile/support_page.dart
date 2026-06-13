import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTicket() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sending) return;

    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.length < 3 || message.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sujet ou message trop court.')),
      );
      return;
    }

    setState(() => sending = true);

    try {
      await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': user.uid,
        'email': user.email ?? '',
        'subject': subject,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      subjectController.clear();
      messageController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoye au support')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envoi impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Aide & Support'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            MotoFixField(
              controller: subjectController,
              hint: 'Sujet',
              icon: Icons.help_outline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            MotoFixField(
              controller: messageController,
              hint: 'Votre message',
              minLines: 5,
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            MotoFixButton(
              label: 'Envoyer',
              loading: sending,
              icon: Icons.send_outlined,
              onPressed: sending ? null : _sendTicket,
            ),
            const SizedBox(height: 24),
            const Text(
              'Mes tickets',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('supportTickets')
                  .where('userId', isEqualTo: user?.uid ?? '_')
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
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

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: MotoFixUi.panelDecoration(radius: 8),
                    child: const Text(
                      'Aucun ticket pour le moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MotoFixUi.textSoft),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final doc in docs) _TicketTile(data: doc.data()),
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

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'open';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(
            status == 'open' ? Icons.mark_email_unread : Icons.mark_email_read,
            color: status == 'open' ? MotoFixUi.orange : MotoFixUi.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject']?.toString() ?? 'Support',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status == 'open' ? 'Ouvert' : 'Traite',
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
