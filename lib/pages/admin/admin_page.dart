import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../../services/admin_service.dart';
import 'drivers_admin_page.dart';
import 'requests_admin_page.dart';
import 'users_admin_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, this.adminService});

  final AdminService? adminService;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final AdminService _adminService;
  late Future<AdminStats> _statsFuture;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? AdminService();
    _statsFuture = _adminService.fetchStats();
  }

  Future<void> logout() {
    return FirebaseAuth.instance.signOut();
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = _adminService.fetchStats();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminDashboard(
        adminService: _adminService,
        statsFuture: _statsFuture,
        onRefresh: _refreshStats,
        onOpenRequests: () => setState(() => currentIndex = 1),
        onOpenDrivers: () => setState(() => currentIndex = 2),
        onOpenUsers: () => setState(() => currentIndex = 3),
      ),
      RequestsAdminPage(adminService: _adminService, embedded: true),
      DriversAdminPage(adminService: _adminService, embedded: true),
      UsersAdminPage(adminService: _adminService, embedded: true),
    ];

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar(
        'Dashboard Admin',
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshStats,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Deconnexion',
            onPressed: logout,
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Demandes',
            ),
            NavigationDestination(
              icon: Icon(Icons.engineering_outlined),
              selectedIcon: Icon(Icons.engineering),
              label: 'Chauffeurs',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Utilisateurs',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({
    required this.adminService,
    required this.statsFuture,
    required this.onRefresh,
    required this.onOpenRequests,
    required this.onOpenDrivers,
    required this.onOpenUsers,
  });

  final AdminService adminService;
  final Future<AdminStats> statsFuture;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenDrivers;
  final VoidCallback onOpenUsers;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: adminService.watchRecentRequests(limit: 6),
      builder: (context, requestSnapshot) {
        final docs = requestSnapshot.data ?? const [];

        return FutureBuilder<AdminStats>(
          future: statsFuture,
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ??
                AdminStats.fromRequests(
                  docs,
                );

            return RefreshIndicator(
              onRefresh: onRefresh,
              color: MotoFixUi.orange,
              backgroundColor: MotoFixUi.panel,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const _AdminHeader(),
                        const SizedBox(height: 18),
                        _StatsGrid(stats: stats),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.receipt_long,
                                title: 'Demandes',
                                subtitle: '${stats.pending} en attente',
                                onTap: onOpenRequests,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.engineering,
                                title: 'Chauffeurs',
                                subtitle:
                                    '${stats.availableDrivers} disponibles',
                                onTap: onOpenDrivers,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _QuickAction(
                          icon: Icons.group,
                          title: 'Utilisateurs',
                          subtitle: '${stats.totalUsers} comptes clients',
                          onTap: onOpenUsers,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Demandes recentes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onOpenRequests,
                              child: const Text('Voir tout'),
                            ),
                          ],
                        ),
                        if (requestSnapshot.connectionState ==
                            ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                color: MotoFixUi.orange,
                              ),
                            ),
                          )
                        else if (docs.isEmpty)
                          const _AdminMessageState(
                            icon: Icons.inbox_outlined,
                            title: 'Aucune demande',
                            message:
                                'Les nouvelles demandes taxi et depannage apparaitront ici.',
                          )
                        else
                          for (final doc in docs)
                            _RecentRequestTile(data: doc.data()),
                        if (statsSnapshot.hasError)
                          _AdminMessageState(
                            icon: Icons.info_outline,
                            title: 'Stats temporairement indisponibles',
                            message: '${statsSnapshot.error}',
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MotoFixUi.gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings, size: 46, color: Colors.white),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MotoFix Admin',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Supervision taxi, depannage et comptes',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Demandes Taxi', stats.taxi, Icons.local_taxi, MotoFixUi.orange),
      _StatItem(
        'Demandes Depannage',
        stats.depannage,
        Icons.build_circle,
        const Color(0xFF8A6AF7),
      ),
      _StatItem('En attente', stats.pending, Icons.hourglass_bottom, Colors.amber),
      _StatItem('Chauffeurs', stats.totalDrivers, Icons.engineering, Colors.cyan),
      _StatItem('Utilisateurs', stats.totalUsers, Icons.group, Colors.green),
      _StatItem(
        'Support',
        stats.openSupportTickets,
        Icons.support_agent,
        Colors.redAccent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 3
            : width >= 560
            ? 3
            : 2;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: width < 380 ? 1.25 : 1.38,
          ),
          itemBuilder: (context, index) => _StatCard(item: items[index]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: MotoFixUi.textSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MotoFixUi.panel,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: MotoFixUi.orange.withValues(alpha: .18),
                child: Icon(icon, color: MotoFixUi.orange),
              ),
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
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: MotoFixUi.textSoft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: MotoFixUi.textSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRequestTile extends StatelessWidget {
  const _RecentRequestTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final request = RequestModel.fromMap('', data);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(
            request.isTaxi ? Icons.local_taxi : Icons.build_circle,
            color: request.isTaxi ? Colors.white : const Color(0xFF8A6AF7),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        RequestStatus.label(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminMessageState extends StatelessWidget {
  const _AdminMessageState({
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
          Icon(icon, color: MotoFixUi.orange, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
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

class _StatItem {
  const _StatItem(this.title, this.value, this.icon, this.color);

  final String title;
  final int value;
  final IconData icon;
  final Color color;
}
