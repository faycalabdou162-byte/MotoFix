import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../request/request_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String filter = 'Tous';

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return MotoFixUi.orange;
      case 'accepte':
        return Colors.blueAccent;
      case 'en_cours':
        return Colors.purpleAccent;
      case 'termine':
        return MotoFixUi.green;
      case 'refuse':
      case 'annule':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'accepte':
        return 'Acceptee';
      case 'en_cours':
        return 'En cours';
      case 'termine':
        return 'Terminee';
      case 'refuse':
        return 'Refusee';
      case 'annule':
        return 'Annulee';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecte')));
    }

    final body = SafeArea(
      child: Column(
        children: [
          if (widget.embedded)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Text(
                'Historique',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: MotoFixUi.panel,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'Tous',
                    active: filter == 'Tous',
                    onTap: () => setState(() => filter = 'Tous'),
                  ),
                  _FilterTab(
                    label: 'Taxi',
                    active: filter == 'taxi',
                    onTap: () => setState(() => filter = 'taxi'),
                  ),
                  _FilterTab(
                    label: 'Depannage',
                    active: filter == 'depannage',
                    onTap: () => setState(() => filter = 'depannage'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: MotoFixUi.orange),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur : ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  if (filter == 'Tous') return true;
                  return doc.data()['type'] == filter;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune demande',
                      style: TextStyle(color: MotoFixUi.textSoft),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final type = (data['type'] ?? '').toString();
                    final status = (data['status'] ?? '').toString();
                    final Timestamp? createdAt = data['createdAt'];

                    final dateText = createdAt == null
                        ? '02 Juin 2026 - 14:30'
                        : DateFormat(
                            'dd MMM yyyy - HH:mm',
                          ).format(createdAt.toDate());

                    final price =
                        (data['price'] as num?)?.round() ??
                        (type == RequestType.taxi ? 2000 : 3000);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RequestPage(requestId: docs[index].id),
                            ),
                          );
                        },
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          decoration: MotoFixUi.panelDecoration(radius: 8),
                          child: Row(
                            children: [
                              Icon(
                                type == RequestType.taxi
                                    ? Icons.local_taxi
                                    : Icons.build_circle,
                                color: type == RequestType.taxi
                                    ? Colors.white
                                    : const Color(0xFF8A6AF7),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      RequestType.label(type),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      statusLabel(status),
                                      style: TextStyle(
                                        color: statusColor(status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        color: MotoFixUi.textSoft,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$price FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Historique'),
      child: body,
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: active ? MotoFixUi.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : MotoFixUi.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
