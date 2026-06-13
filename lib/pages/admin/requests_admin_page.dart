import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../../services/admin_service.dart';

class RequestsAdminPage extends StatefulWidget {
  const RequestsAdminPage({
    super.key,
    this.adminService,
    this.embedded = false,
  });

  final AdminService? adminService;
  final bool embedded;

  @override
  State<RequestsAdminPage> createState() => _RequestsAdminPageState();
}

class _RequestsAdminPageState extends State<RequestsAdminPage> {
  late final AdminService _adminService;
  String typeFilter = 'all';
  String statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? AdminService();
  }

  List<RequestModel> _filter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final requests = docs.map((doc) {
      return RequestModel.fromMap(doc.id, doc.data());
    }).where((request) {
      final typeMatch = typeFilter == 'all' || request.type == typeFilter;
      final statusMatch =
          statusFilter == 'all' || request.status == statusFilter;
      return typeMatch && statusMatch;
    }).toList();

    return requests;
  }

  Future<void> _updateStatus(RequestModel request, String status) async {
    try {
      await _adminService.updateRequestStatus(
        requestId: request.id,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande mise a jour')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise a jour impossible: $error')),
      );
    }
  }

  Future<void> _deleteRequest(RequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la demande ?'),
          content: const Text('Cette action est definitive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande supprimee')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible: $error')),
      );
    }
  }

  void _openDetails(RequestModel request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MotoFixUi.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _RequestDetailsSheet(
          request: request,
          adminService: _adminService,
          onStatus: (status) => _updateStatus(request, status),
          onDelete: () => _deleteRequest(request),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _adminService.watchRecentRequests(limit: 80),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MotoFixUi.orange),
            );
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              title: 'Erreur de chargement',
              message: '${snapshot.error}',
            );
          }

          final requests = _filter(snapshot.data ?? const []);
          final stats = AdminStats.fromRequests(snapshot.data ?? const []);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: MotoFixUi.orange,
            backgroundColor: MotoFixUi.panel,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _StatsWrap(stats: stats),
                const SizedBox(height: 14),
                _FiltersBar(
                  typeFilter: typeFilter,
                  statusFilter: statusFilter,
                  onTypeChanged: (value) => setState(() => typeFilter = value),
                  onStatusChanged: (value) =>
                      setState(() => statusFilter = value),
                ),
                const SizedBox(height: 12),
                Text(
                  '${requests.length} demandes',
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
                const SizedBox(height: 10),
                if (requests.isEmpty)
                  const _MessageState(
                    icon: Icons.inbox_outlined,
                    title: 'Aucune demande',
                    message: 'Aucune demande ne correspond aux filtres.',
                  )
                else
                  for (final request in requests)
                    _RequestTile(
                      request: request,
                      onTap: () => _openDetails(request),
                      onAccept: () =>
                          _updateStatus(request, RequestStatus.accepted),
                      onProgress: () =>
                          _updateStatus(request, RequestStatus.inProgress),
                      onComplete: () =>
                          _updateStatus(request, RequestStatus.completed),
                      onRefuse: () =>
                          _updateStatus(request, RequestStatus.refused),
                    ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.embedded) return body;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Demandes Admin'),
      child: body,
    );
  }
}

class _StatsWrap extends StatelessWidget {
  const _StatsWrap({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip('Total', stats.totalRequests, Colors.white),
        _StatChip('Taxi', stats.taxi, MotoFixUi.orange),
        _StatChip('Depannage', stats.depannage, const Color(0xFF8A6AF7)),
        _StatChip('Attente', stats.pending, Colors.amber),
        _StatChip('Cours', stats.inProgress, Colors.purpleAccent),
        _StatChip('Termine', stats.completed, MotoFixUi.green),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.title, this.value, this.color);

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: MotoFixUi.panelDecoration(radius: 8),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: MotoFixUi.textSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.typeFilter,
    required this.statusFilter,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final String typeFilter;
  final String statusFilter;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SegmentedFilter(
          value: typeFilter,
          values: const {
            'all': 'Tous',
            RequestType.taxi: 'Taxi',
            RequestType.depannage: 'Depannage',
          },
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 8),
        _SegmentedFilter(
          value: statusFilter,
          values: const {
            'all': 'Tous',
            RequestStatus.pending: 'Attente',
            RequestStatus.accepted: 'Accepte',
            RequestStatus.inProgress: 'Cours',
            RequestStatus.completed: 'Termine',
          },
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: MotoFixUi.panel,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final item in values.entries)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(item.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: value == item.key
                        ? MotoFixUi.orange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.value,
                      style: TextStyle(
                        color: value == item.key
                            ? Colors.white
                            : MotoFixUi.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onTap,
    required this.onAccept,
    required this.onProgress,
    required this.onComplete,
    required this.onRefuse,
  });

  final RequestModel request;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onProgress;
  final VoidCallback onComplete;
  final VoidCallback onRefuse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          request.pickupAddress,
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
                  _StatusPill(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    text: 'Accepter',
                    icon: Icons.verified,
                    color: Colors.blue,
                    onTap: request.status == RequestStatus.accepted
                        ? null
                        : onAccept,
                  ),
                  _ActionButton(
                    text: 'En cours',
                    icon: Icons.route,
                    color: Colors.purple,
                    onTap: request.status == RequestStatus.inProgress
                        ? null
                        : onProgress,
                  ),
                  _ActionButton(
                    text: 'Terminer',
                    icon: Icons.check,
                    color: Colors.green,
                    onTap: request.status == RequestStatus.completed
                        ? null
                        : onComplete,
                  ),
                  _ActionButton(
                    text: 'Refuser',
                    icon: Icons.close,
                    color: Colors.red,
                    onTap: request.status == RequestStatus.refused
                        ? null
                        : onRefuse,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestDetailsSheet extends StatefulWidget {
  const _RequestDetailsSheet({
    required this.request,
    required this.adminService,
    required this.onStatus,
    required this.onDelete,
  });

  final RequestModel request;
  final AdminService adminService;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;

  @override
  State<_RequestDetailsSheet> createState() => _RequestDetailsSheetState();
}

class _RequestDetailsSheetState extends State<_RequestDetailsSheet> {
  late final TextEditingController notesController;
  bool savingNotes = false;
  bool assigning = false;

  @override
  void initState() {
    super.initState();
    notesController = TextEditingController(text: widget.request.adminNotes);
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => savingNotes = true);
    try {
      await widget.adminService.updateRequestNotes(
        requestId: widget.request.id,
        notes: notesController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes enregistrees')),
      );
    } finally {
      if (mounted) setState(() => savingNotes = false);
    }
  }

  Future<void> _assignDriver(String driverId) async {
    if (assigning) return;
    setState(() => assigning = true);
    try {
      await widget.adminService.assignDriver(
        requestId: widget.request.id,
        driverId: driverId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chauffeur affecte')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Affectation impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final createdAt = request.createdAt == null
        ? ''
        : DateFormat('dd MMM yyyy - HH:mm').format(request.createdAt!);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      maxChildSize: .94,
      minChildSize: .45,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              RequestType.label(request.type),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$createdAt - ${request.price} FCFA',
              style: const TextStyle(color: MotoFixUi.textSoft),
            ),
            const SizedBox(height: 16),
            _DetailLine('Client', request.clientName),
            _DetailLine('Email', request.email),
            _DetailLine('Telephone', request.phone),
            _DetailLine('Adresse', request.pickupAddress),
            if (request.destinationAddress.isNotEmpty)
              _DetailLine('Destination', request.destinationAddress),
            if (request.description.isNotEmpty)
              _DetailLine('Description', request.description),
            if (request.hasDriver)
              _DetailLine(
                'Chauffeur',
                '${request.driverName} - ${request.driverPlate}',
              ),
            const SizedBox(height: 18),
            const Text(
              'Affecter un chauffeur',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: widget.adminService.watchDrivers(),
              builder: (context, snapshot) {
                final drivers = (snapshot.data ?? const []).where((doc) {
                  final data = doc.data();
                  return data['active'] != false && data['available'] != false;
                }).toList();

                if (drivers.isEmpty) {
                  return const Text(
                    'Aucun chauffeur disponible.',
                    style: TextStyle(color: MotoFixUi.textSoft),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final driver in drivers)
                      ChoiceChip(
                        label: Text(driver.data()['name']?.toString() ?? ''),
                        selected: request.driverId == driver.id,
                        onSelected: assigning
                            ? null
                            : (_) => _assignDriver(driver.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            MotoFixField(
              controller: notesController,
              hint: 'Notes internes',
              minLines: 3,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            MotoFixButton(
              label: 'Enregistrer les notes',
              loading: savingNotes,
              icon: Icons.save_outlined,
              onPressed: savingNotes ? null : _saveNotes,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionButton(
                  text: 'Accepter',
                  icon: Icons.verified,
                  color: Colors.blue,
                  onTap: () => widget.onStatus(RequestStatus.accepted),
                ),
                _ActionButton(
                  text: 'En cours',
                  icon: Icons.route,
                  color: Colors.purple,
                  onTap: () => widget.onStatus(RequestStatus.inProgress),
                ),
                _ActionButton(
                  text: 'Terminer',
                  icon: Icons.check,
                  color: Colors.green,
                  onTap: () => widget.onStatus(RequestStatus.completed),
                ),
                _ActionButton(
                  text: 'Refuser',
                  icon: Icons.close,
                  color: Colors.red,
                  onTap: () => widget.onStatus(RequestStatus.refused),
                ),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: MotoFixUi.textSoft),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RequestStatus.accepted => Colors.blueAccent,
      RequestStatus.inProgress => Colors.purpleAccent,
      RequestStatus.completed => MotoFixUi.green,
      RequestStatus.refused || RequestStatus.cancelled => Colors.redAccent,
      _ => MotoFixUi.orange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        RequestStatus.label(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Column(
        children: [
          Icon(icon, color: MotoFixUi.orange, size: 46),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MotoFixUi.textSoft),
          ),
        ],
      ),
    );
  }
}
