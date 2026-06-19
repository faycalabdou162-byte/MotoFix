import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/motofix_ui.dart';
import '../../features/map/presentation/live_tracking_page.dart';
import '../../models/request_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/modern_bottom_nav.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../notifications_page.dart';
import '../profile/profile_page.dart';
import '../request/request_page.dart';
import '../services/depannage_page.dart';
import '../services/taxi_page.dart';
import 'history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeContent(),
    HistoryPage(embedded: true),
    ProfilePage(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: ModernBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          ModernNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Accueil',
          ),
          ModernNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'Historique',
          ),
          ModernNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> getRequestsStream() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getRequestsStream(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(),
                const SizedBox(height: 18),
                _ServiceCard(
                  title: 'Demander un',
                  strong: 'TAXI MOTO',
                  icon: Icons.local_taxi,
                  gradient: MotoFixUi.gradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaxiPage()),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                _ServiceCard(
                  title: '1 clic —',
                  strong: 'DÉPANNAGE',
                  icon: Icons.build,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DepannagePage()),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Historique',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryPage(),
                        ),
                      ),
                      child: const Text(
                        'Voir tout',
                        style: TextStyle(
                          color: MotoFixUi.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SkeletonLoader(height: 72, count: 3)
                else if (docs.isEmpty)
                  const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Aucune demande récente',
                    subtitle: 'Vos dépannages et courses apparaîtront ici.',
                  )
                else
                  for (final doc in docs)
                    _HistoryPreview(id: doc.id, data: doc.data()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
                Positioned(
                  right: 12,
                  top: 11,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: MotoFixUi.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(text: 'MotoFix '),
                TextSpan(
                  text: 'Niger',
                  style: TextStyle(color: MotoFixUi.orange),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Que souhaitez-vous faire ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.strong,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.trailing,
  });

  final String title;
  final String strong;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Ink(
        height: 102,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 58, color: Colors.white.withValues(alpha: .2)),
                  const SizedBox(
                    width: 82,
                    height: 54,
                    child: CustomPaint(painter: MotoLinePainter(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    strong,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? 'taxi';
    final status = data['status']?.toString() ?? 'termine';
    final Timestamp? createdAt = data['createdAt'];
    final dateText = createdAt == null
        ? '02 Juin 2026 - 14:30'
        : DateFormat('dd MMM yyyy - HH:mm').format(createdAt.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          final status = data['status']?.toString() ?? '';
          if (RequestStatus.activeStatuses.contains(status)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveTrackingPage(requestId: id),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RequestPage(requestId: id)),
            );
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: MotoFixUi.panelDecoration(radius: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  type == RequestType.taxi
                      ? Icons.local_taxi
                      : Icons.build_circle,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RequestType.label(type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                _statusLabel(status),
                style: TextStyle(
                  color: _statusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return RequestStatus.label(status);
  }

  Color _statusColor(String status) {
    return switch (status) {
      RequestStatus.pending => MotoFixUi.orange,
      RequestStatus.accepted => Colors.blueAccent,
      RequestStatus.inProgress => Colors.purpleAccent,
      RequestStatus.completed => MotoFixUi.green,
      RequestStatus.refused || RequestStatus.cancelled => Colors.redAccent,
      _ => Colors.grey,
    };
  }
}
