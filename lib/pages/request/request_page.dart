import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../home/map_page.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key, this.requestId});

  final String? requestId;

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final RequestService _requestService = RequestService();
  bool _cancelling = false;

  Future<void> _cancelRequest(RequestModel request) async {
    if (_cancelling || !request.canCancel) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Annuler la demande ?'),
          content: const Text('Cette action informera MotoFix Niger.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Retour'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);

    try {
      await _requestService.cancelRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande annulee')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Annulation impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestId = widget.requestId;

    if (requestId == null) {
      return MotoFixUi.page(
        appBar: MotoFixUi.appBar('Suivi de votre demande'),
        child: const _EmptyRequestState(),
      );
    }

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Suivi de votre demande'),
      child: StreamBuilder<RequestModel?>(
        stream: _requestService.watchRequest(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MotoFixUi.orange),
            );
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              title: 'Suivi indisponible',
              message: '${snapshot.error}',
            );
          }

          final request = snapshot.data;
          if (request == null) {
            return const _MessageState(
              icon: Icons.inbox_outlined,
              title: 'Demande introuvable',
              message: 'Cette demande a peut-etre ete supprimee.',
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RequestSummary(request: request),
                          const SizedBox(height: 22),
                          RequestStatusTimeline(request: request),
                          if (request.hasDriver) ...[
                            const SizedBox(height: 8),
                            _DriverPanel(request: request),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (request.status == RequestStatus.accepted ||
                      request.status == RequestStatus.inProgress) ...[
                    MotoFixButton(
                      label: 'Voir la carte',
                      icon: Icons.map_outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapPage(requestId: request.id),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: request.canCancel && !_cancelling
                          ? () => _cancelRequest(request)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        disabledForegroundColor: Colors.white24,
                        side: BorderSide(
                          color: request.canCancel
                              ? Colors.redAccent
                              : Colors.white24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _cancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.redAccent,
                              ),
                            )
                          : const Icon(Icons.close),
                      label: Text(
                        request.canCancel
                            ? 'Annuler la demande'
                            : 'Demande ${RequestStatus.label(request.status).toLowerCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final date = request.createdAt == null
        ? 'En cours'
        : DateFormat('dd MMM yyyy - HH:mm').format(request.createdAt!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: request.isTaxi
                ? MotoFixUi.orange
                : const Color(0xFF6A55C9),
            child: Icon(
              request.isTaxi ? Icons.local_taxi : Icons.build_circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  RequestType.label(request.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: MotoFixUi.textSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${request.price} FCFA',
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

class _DriverPanel extends StatelessWidget {
  const _DriverPanel({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: MotoFixUi.orange2,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${request.driverVehicle} - ${request.driverPlate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MotoFixUi.textSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 17),
          const SizedBox(width: 4),
          const Text(
            '4.8',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class RequestStatusTimeline extends StatelessWidget {
  const RequestStatusTimeline({super.key, required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final isCancelled = request.status == RequestStatus.cancelled ||
        request.status == RequestStatus.refused;

    final items = isCancelled
        ? [
            _TimelineItem(
              'Demande envoyee',
              _createdLabel(request),
              Icons.check_circle,
              true,
            ),
            _TimelineItem(
              RequestStatus.label(request.status),
              request.status == RequestStatus.refused
                  ? 'La demande a ete refusee'
                  : 'La demande a ete annulee',
              Icons.cancel,
              true,
              active: true,
              danger: true,
            ),
          ]
        : [
            _TimelineItem(
              'Demande envoyee',
              _createdLabel(request),
              Icons.check_circle,
              true,
            ),
            _TimelineItem(
              'Recherche en cours',
              'Un chauffeur va prendre la demande',
              Icons.radar,
              _isAtLeast(RequestStatus.accepted),
              active: request.status == RequestStatus.pending,
            ),
            _TimelineItem(
              'Chauffeur trouve',
              request.hasDriver
                  ? '${request.driverName} - ${request.driverPlate}'
                  : 'En attente d affectation',
              Icons.engineering,
              _isAtLeast(RequestStatus.inProgress),
              active: request.status == RequestStatus.accepted,
            ),
            _TimelineItem(
              'En route vers vous',
              'Arrivee estimee dans 5 min',
              Icons.local_taxi,
              request.status == RequestStatus.completed,
              active: request.status == RequestStatus.inProgress,
            ),
            _TimelineItem(
              'Arrive',
              'Le service est termine',
              Icons.flag,
              request.status == RequestStatus.completed,
            ),
          ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(
            item: items[i],
            isLast: i == items.length - 1,
          ),
      ],
    );
  }

  bool _isAtLeast(String checkpoint) {
    const order = [
      RequestStatus.pending,
      RequestStatus.accepted,
      RequestStatus.inProgress,
      RequestStatus.completed,
    ];

    final current = order.indexOf(request.status);
    final target = order.indexOf(checkpoint);

    return current >= target && current != -1 && target != -1;
  }

  String _createdLabel(RequestModel request) {
    final createdAt = request.createdAt;
    if (createdAt == null) return 'A l instant';
    return DateFormat('dd MMM yyyy - HH:mm').format(createdAt);
  }
}

class _TimelineItem {
  const _TimelineItem(
    this.title,
    this.subtitle,
    this.icon,
    this.done, {
    this.active = false,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool active;
  final bool danger;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.isLast,
  });

  final _TimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = item.danger
        ? Colors.redAccent
        : item.active
        ? MotoFixUi.orange
        : item.done
        ? MotoFixUi.green
        : const Color(0xFF738196);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: color,
                child: Icon(item.icon, color: Colors.white, size: 19),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: item.done ? MotoFixUi.green : Colors.white12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: MotoFixUi.textSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: color,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequestState extends StatelessWidget {
  const _EmptyRequestState();

  @override
  Widget build(BuildContext context) {
    return const _MessageState(
      icon: Icons.route_outlined,
      title: 'Aucune demande selectionnee',
      message: 'Ouvrez une demande depuis l historique pour suivre son avancee.',
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: MotoFixUi.orange, size: 46),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MotoFixUi.textSoft),
            ),
          ],
        ),
      ),
    );
  }
}
