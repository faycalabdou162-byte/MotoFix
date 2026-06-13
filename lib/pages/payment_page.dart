import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/motofix_ui.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Mes paiements'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MotoFixUi.panelDecoration(radius: 8),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: MotoFixUi.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobile Money',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Paiement en especes ou mobile money a la fin du trajet.',
                          style: TextStyle(color: MotoFixUi.textSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Historique',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('payments')
                  .where('userId', isEqualTo: user?.uid ?? '_')
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: MotoFixUi.orange,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyPaymentState();
                }

                return Column(
                  children: [
                    for (final doc in docs) _PaymentTile(data: doc.data()),
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

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.round() ?? 0;
    final method = data['method']?.toString() ?? 'Mobile Money';
    final status = data['status']?.toString() ?? 'paid';
    final createdAt = data['createdAt'] as Timestamp?;
    final date = createdAt == null
        ? ''
        : DateFormat('dd MMM yyyy - HH:mm').format(createdAt.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: MotoFixUi.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status == 'paid' ? 'Paye - $date' : '$status - $date',
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
              ],
            ),
          ),
          Text(
            '$amount FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPaymentState extends StatelessWidget {
  const _EmptyPaymentState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: const Text(
        'Aucun paiement enregistre pour le moment.',
        textAlign: TextAlign.center,
        style: TextStyle(color: MotoFixUi.textSoft),
      ),
    );
  }
}
