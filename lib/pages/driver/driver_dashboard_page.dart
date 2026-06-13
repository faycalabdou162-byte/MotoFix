import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../../services/driver_service.dart';
import '../auth/login_page.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key, this.driverService});

  final DriverService? driverService;

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  late final DriverService _driverService;
  late Future<void> _setupFuture;
  int currentIndex = 0;
  bool syncingLocation = false;

  @override
  void initState() {
    super.initState();
    _driverService = widget.driverService ?? DriverService();
    _setupFuture = _driverService.ensureDriverProfile();
  }

  Future<void> _retrySetup() async {
    setState(() {
      _setupFuture = _driverService.ensureDriverProfile();
    });
    await _setupFuture;
  }

  Future<void> _syncLocation() async {
    if (syncingLocation) return;

    setState(() => syncingLocation = true);
    try {
      await _driverService.syncCurrentLocation();
      if (!mounted) return;
      _showMessage('Position chauffeur mise a jour');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Localisation impossible: $error');
    } finally {
      if (mounted) setState(() => syncingLocation = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _runAction(
    String successMessage,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Action impossible: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _setupFuture,
      builder: (context, setupSnapshot) {
        if (setupSnapshot.connectionState == ConnectionState.waiting) {
          return MotoFixUi.page(
            child: const Center(
              child: CircularProgressIndicator(color: MotoFixUi.orange),
            ),
          );
        }

        if (setupSnapshot.hasError) {
          return MotoFixUi.page(
            child: _DriverMessageState(
              icon: Icons.engineering_outlined,
              title: 'Profil chauffeur indisponible',
              message: '${setupSnapshot.error}',
              actionLabel: 'Reessayer',
              onAction: _retrySetup,
            ),
          );
        }

        return StreamBuilder<DriverProfile?>(
          stream: _driverService.watchCurrentDriver(),
          builder: (context, driverSnapshot) {
            final driver = driverSnapshot.data;

            if (driverSnapshot.connectionState == ConnectionState.waiting) {
              return MotoFixUi.page(
                child: const Center(
                  child: CircularProgressIndicator(color: MotoFixUi.orange),
                ),
              );
            }

            if (driver == null) {
              return MotoFixUi.page(
                child: _DriverMessageState(
                  icon: Icons.person_off_outlined,
                  title: 'Compte chauffeur a configurer',
                  message:
                      'Demandez a un admin de valider votre profil chauffeur.',
                  actionLabel: 'Reessayer',
                  onAction: _retrySetup,
                ),
              );
            }

            final pages = [
              _AvailableRequestsTab(
                driver: driver,
                driverService: _driverService,
                onAccept: (request) => _runAction(
                  'Demande acceptee',
                  () => _driverService.acceptRequest(
                    request: request,
                    driver: driver,
                  ),
                ),
                onRefuse: (request) => _runAction(
                  'Demande refusee',
                  () => _driverService.refuseRequest(request.id),
                ),
              ),
              _DriverJobsTab(
                driver: driver,
                driverService: _driverService,
                onStart: (request) => _runAction(
                  'Course demarree',
                  () => _driverService.startRequest(request.id),
                ),
                onComplete: (request) => _runAction(
                  'Course terminee',
                  () => _driverService.completeRequest(request.id),
                ),
              ),
              _DriverProfileTab(
                driver: driver,
                onAvailability: (available) => _runAction(
                  available ? 'Vous etes disponible' : 'Mode indisponible',
                  () => _driverService.setAvailability(available),
                ),
                onSyncLocation: _syncLocation,
              ),
            ];

            return MotoFixUi.page(
              appBar: MotoFixUi.appBar(
                'Espace Chauffeur',
                actions: [
                  IconButton(
                    tooltip: 'Synchroniser la position',
                    onPressed: syncingLocation ? null : _syncLocation,
                    icon: syncingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: MotoFixUi.orange,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location_outlined),
                  ),
                  IconButton(
                    tooltip: 'Deconnexion',
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              child: pages[currentIndex],
              bottomNavigationBar: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: const Color(0xFF071322),
                  indicatorColor: Colors.transparent,
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      color: states.contains(WidgetState.selected)
                          ? MotoFixUi.orange
                          : MotoFixUi.textSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? MotoFixUi.orange
                          : MotoFixUi.textSoft,
                      size: 23,
                    ),
                  ),
                ),
                child: NavigationBar(
                  height: 62,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => currentIndex = index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.inbox_outlined),
                      selectedIcon: Icon(Icons.inbox),
                      label: 'Demandes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.route_outlined),
                      selectedIcon: Icon(Icons.route),
                      label: 'Courses',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AvailableRequestsTab extends StatelessWidget {
  const _AvailableRequestsTab({
    required this.driver,
    required this.driverService,
    required this.onAccept,
    required this.onRefuse,
  });

  final DriverProfile driver;
  final DriverService driverService;
  final ValueChanged<RequestModel> onAccept;
  final ValueChanged<RequestModel> onRefuse;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<RequestModel>>(
        stream: driverService.watchAvailableRequests(),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <RequestModel>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _DriverHero(driver: driver),
              if (!driver.available || !driver.active) ...[
                const SizedBox(height: 12),
                _AvailabilityWarning(driver: driver),
              ],
              const SizedBox(height: 18),
              const Text(
                'Demandes disponibles',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: MotoFixUi.orange),
                  ),
                )
              else if (requests.isEmpty)
                const _DriverEmptyCard(
                  icon: Icons.inbox_outlined,
                  title: 'Aucune demande en attente',
                  message:
                      'Les nouvelles demandes taxi et depannage apparaitront ici.',
                )
              else
                for (final request in requests)
                  _DriverRequestCard(
                    request: request,
                    primaryLabel: 'Accepter',
                    primaryIcon: Icons.verified_outlined,
                    primaryColor: MotoFixUi.green,
                    primaryEnabled: driver.available && driver.active,
                    onPrimary: () => onAccept(request),
                    secondaryLabel: 'Refuser',
                    secondaryIcon: Icons.close,
                    secondaryColor: Colors.redAccent,
                    onSecondary: () => onRefuse(request),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _DriverJobsTab extends StatelessWidget {
  const _DriverJobsTab({
    required this.driver,
    required this.driverService,
    required this.onStart,
    required this.onComplete,
  });

  final DriverProfile driver;
  final DriverService driverService;
  final ValueChanged<RequestModel> onStart;
  final ValueChanged<RequestModel> onComplete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<RequestModel>>(
        stream: driverService.watchDriverRequests(driver.id),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <RequestModel>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              const Text(
                'Mes courses',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: MotoFixUi.orange),
                  ),
                )
              else if (requests.isEmpty)
                const _DriverEmptyCard(
                  icon: Icons.route_outlined,
                  title: 'Aucune course affectee',
                  message:
                      'Acceptez une demande pour la retrouver dans cet espace.',
                )
              else
                for (final request in requests) _jobCardFor(request),
            ],
          );
        },
      ),
    );
  }

  Widget _jobCardFor(RequestModel request) {
    if (request.status == RequestStatus.accepted) {
      return _DriverRequestCard(
        request: request,
        primaryLabel: 'En route',
        primaryIcon: Icons.route,
        primaryColor: MotoFixUi.orange,
        onPrimary: () => onStart(request),
      );
    }

    if (request.status == RequestStatus.inProgress) {
      return _DriverRequestCard(
        request: request,
        primaryLabel: 'Terminer',
        primaryIcon: Icons.check_circle_outline,
        primaryColor: MotoFixUi.green,
        onPrimary: () => onComplete(request),
      );
    }

    return _DriverRequestCard(request: request);
  }
}

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab({
    required this.driver,
    required this.onAvailability,
    required this.onSyncLocation,
  });

  final DriverProfile driver;
  final ValueChanged<bool> onAvailability;
  final VoidCallback onSyncLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          _DriverHero(driver: driver),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: MotoFixUi.panelDecoration(radius: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: driver.available,
              activeThumbColor: MotoFixUi.orange,
              title: const Text(
                'Disponible',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: const Text(
                'Recevoir les demandes clients',
                style: TextStyle(color: MotoFixUi.textSoft),
              ),
              onChanged: driver.active ? onAvailability : null,
            ),
          ),
          const SizedBox(height: 10),
          _ProfileLine(
            icon: Icons.phone_iphone,
            title: 'Telephone',
            value: driver.phone.isEmpty ? 'Non renseigne' : driver.phone,
          ),
          _ProfileLine(
            icon: Icons.two_wheeler,
            title: 'Vehicule',
            value: driver.vehicle,
          ),
          _ProfileLine(
            icon: Icons.confirmation_number_outlined,
            title: 'Immatriculation',
            value: driver.plateNumber.isEmpty
                ? 'Non renseignee'
                : driver.plateNumber,
          ),
          _ProfileLine(
            icon: Icons.star_outline,
            title: 'Note',
            value: driver.rating.toStringAsFixed(1),
          ),
          const SizedBox(height: 14),
          MotoFixButton(
            label: 'Synchroniser ma position',
            icon: Icons.my_location_outlined,
            onPressed: onSyncLocation,
          ),
        ],
      ),
    );
  }
}

class _DriverHero extends StatelessWidget {
  const _DriverHero({required this.driver});

  final DriverProfile driver;

  @override
  Widget build(BuildContext context) {
    final initial = driver.displayName.trim()[0].toUpperCase();
    final statusColor = driver.active
        ? driver.available
              ? MotoFixUi.green
              : Colors.amber
        : Colors.redAccent;
    final statusLabel = driver.active
        ? driver.available
              ? 'Disponible'
              : 'Indisponible'
        : 'Compte inactif';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172A44), Color(0xFF0B1728)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MotoFixUi.orange,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${driver.vehicle} ${driver.plateNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withValues(alpha: .4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityWarning extends StatelessWidget {
  const _AvailabilityWarning({required this.driver});

  final DriverProfile driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(
            driver.active ? Icons.pause_circle_outline : Icons.block,
            color: driver.active ? Colors.amber : Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              driver.active
                  ? 'Vous etes indisponible. Activez le profil pour accepter une demande.'
                  : 'Votre compte chauffeur est inactif. Contactez un admin.',
              style: const TextStyle(color: MotoFixUi.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRequestCard extends StatelessWidget {
  const _DriverRequestCard({
    required this.request,
    this.primaryLabel,
    this.primaryIcon,
    this.primaryColor = MotoFixUi.orange,
    this.primaryEnabled = true,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryColor = Colors.redAccent,
    this.onSecondary,
  });

  final RequestModel request;
  final String? primaryLabel;
  final IconData? primaryIcon;
  final Color primaryColor;
  final bool primaryEnabled;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final Color secondaryColor;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final createdAt = request.createdAt == null
        ? 'Date indisponible'
        : DateFormat('dd MMM yyyy - HH:mm').format(request.createdAt!);
    final serviceColor = request.isTaxi
        ? MotoFixUi.orange
        : const Color(0xFF8A6AF7);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: serviceColor,
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
                      createdAt,
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
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: request.pickupAddress,
          ),
          if (request.destinationAddress.isNotEmpty)
            _InfoLine(
              icon: Icons.flag_outlined,
              text: request.destinationAddress,
            ),
          if (request.description.isNotEmpty)
            _InfoLine(icon: Icons.notes_outlined, text: request.description),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Prix estime',
                  style: TextStyle(color: MotoFixUi.textSoft),
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
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (primaryLabel != null)
                  _SmallActionButton(
                    label: primaryLabel!,
                    icon: primaryIcon ?? Icons.check,
                    color: primaryColor,
                    onTap: primaryEnabled ? onPrimary : null,
                  ),
                if (secondaryLabel != null)
                  _SmallActionButton(
                    label: secondaryLabel!,
                    icon: secondaryIcon ?? Icons.close,
                    color: secondaryColor,
                    onTap: onSecondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MotoFixUi.textSoft, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: MotoFixUi.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(icon, color: MotoFixUi.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: MotoFixUi.textSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: .22),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
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
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Text(
        RequestStatus.label(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DriverEmptyCard extends StatelessWidget {
  const _DriverEmptyCard({
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
          Icon(icon, color: MotoFixUi.orange, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
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

class _DriverMessageState extends StatelessWidget {
  const _DriverMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: MotoFixUi.orange, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MotoFixUi.textSoft),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 180,
                child: MotoFixButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
