import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../home/history_page.dart';
import '../profile/support_page.dart';
import 'depannage_page.dart';
import 'taxi_page.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Services MotoFix'),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: MotoFixUi.gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.grid_view, size: 38, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Centre de services',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Acces rapide a MotoFix Niger',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _ServiceCard(
                      title: 'Taxi',
                      icon: Icons.local_taxi,
                      color: MotoFixUi.orange,
                      page: const TaxiPage(),
                    ),
                    _ServiceCard(
                      title: 'Depannage',
                      icon: Icons.build_circle,
                      color: const Color(0xFF8A6AF7),
                      page: const DepannagePage(),
                    ),
                    _ServiceCard(
                      title: 'Historique',
                      icon: Icons.history,
                      color: Colors.green,
                      page: const HistoryPage(),
                    ),
                    _ServiceCard(
                      title: 'Support',
                      icon: Icons.support_agent,
                      color: Colors.blueAccent,
                      page: const SupportPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MotoFixUi.panel,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: .18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
