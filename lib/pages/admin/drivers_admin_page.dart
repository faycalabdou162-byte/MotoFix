import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../services/admin_service.dart';

class DriversAdminPage extends StatefulWidget {
  const DriversAdminPage({
    super.key,
    this.adminService,
    this.embedded = false,
  });

  final AdminService? adminService;
  final bool embedded;

  @override
  State<DriversAdminPage> createState() => _DriversAdminPageState();
}

class _DriversAdminPageState extends State<DriversAdminPage> {
  late final AdminService _adminService;

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? AdminService();
  }

  Future<void> _openDriverForm({
    String? driverId,
    Map<String, dynamic>? data,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MotoFixUi.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _DriverFormSheet(
          data: data,
          onSave: (draft) async {
            if (driverId == null) {
              await _adminService.createDriver(draft);
            } else {
              await _adminService.updateDriver(
                driverId: driverId,
                driver: draft,
              );
            }
          },
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chauffeur enregistre')),
      );
    }
  }

  Future<void> _deleteDriver(String driverId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le chauffeur ?'),
          content: const Text('Les demandes deja affectees gardent son nom.'),
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

    if (confirmed == true) {
      await _adminService.deleteDriver(driverId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _adminService.watchDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MotoFixUi.orange),
            );
          }

          final drivers = snapshot.data ?? const [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              MotoFixButton(
                label: 'Ajouter un chauffeur',
                icon: Icons.person_add_alt,
                onPressed: () => _openDriverForm(),
              ),
              const SizedBox(height: 16),
              if (drivers.isEmpty)
                const _DriverMessage()
              else
                for (final driver in drivers)
                  _DriverTile(
                    id: driver.id,
                    data: driver.data(),
                    onEdit: () => _openDriverForm(
                      driverId: driver.id,
                      data: driver.data(),
                    ),
                    onToggle: (available) {
                      _adminService.setDriverAvailability(
                        driverId: driver.id,
                        available: available,
                      );
                    },
                    onDelete: () => _deleteDriver(driver.id),
                  ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) return body;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Chauffeurs'),
      child: body,
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? 'Chauffeur';
    final phone = data['phone']?.toString() ?? '';
    final vehicle = data['vehicle']?.toString() ?? 'Moto';
    final plate = data['plateNumber']?.toString() ?? '';
    final available = data['available'] as bool? ?? true;
    final active = data['active'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: available ? MotoFixUi.orange : Colors.white12,
            child: Icon(
              active ? Icons.engineering : Icons.person_off,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$phone - $vehicle - $plate',
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
          Switch(
            value: available,
            activeThumbColor: MotoFixUi.orange,
            onChanged: onToggle,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverFormSheet extends StatefulWidget {
  const _DriverFormSheet({
    required this.onSave,
    this.data,
  });

  final Map<String, dynamic>? data;
  final Future<void> Function(DriverDraft draft) onSave;

  @override
  State<_DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<_DriverFormSheet> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController vehicleController;
  late final TextEditingController plateController;
  bool saving = false;
  bool active = true;
  bool available = true;

  @override
  void initState() {
    super.initState();
    final data = widget.data ?? const <String, dynamic>{};
    nameController = TextEditingController(text: data['name']?.toString() ?? '');
    phoneController = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );
    vehicleController = TextEditingController(
      text: data['vehicle']?.toString() ?? '',
    );
    plateController = TextEditingController(
      text: data['plateNumber']?.toString() ?? '',
    );
    active = data['active'] as bool? ?? true;
    available = data['available'] as bool? ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    vehicleController.dispose();
    plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      await widget.onSave(
        DriverDraft(
          name: nameController.text,
          phone: phoneController.text,
          vehicle: vehicleController.text,
          plateNumber: plateController.text,
          active: active,
          available: available,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            MotoFixField(
              controller: nameController,
              hint: 'Nom du chauffeur',
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
              controller: vehicleController,
              hint: 'Moto',
              icon: Icons.two_wheeler,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            MotoFixField(
              controller: plateController,
              hint: 'Immatriculation',
              icon: Icons.confirmation_number_outlined,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: active,
              activeThumbColor: MotoFixUi.orange,
              title: const Text(
                'Actif',
                style: TextStyle(color: Colors.white),
              ),
              onChanged: (value) => setState(() => active = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: available,
              activeThumbColor: MotoFixUi.orange,
              title: const Text(
                'Disponible',
                style: TextStyle(color: Colors.white),
              ),
              onChanged: (value) => setState(() => available = value),
            ),
            const SizedBox(height: 12),
            MotoFixButton(
              label: 'Enregistrer',
              loading: saving,
              icon: Icons.save_outlined,
              onPressed: saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverMessage extends StatelessWidget {
  const _DriverMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: const Text(
        'Aucun chauffeur enregistre.',
        textAlign: TextAlign.center,
        style: TextStyle(color: MotoFixUi.textSoft),
      ),
    );
  }
}
