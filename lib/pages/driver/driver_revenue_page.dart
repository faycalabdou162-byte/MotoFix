import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../../services/revenue_service.dart';

class DriverRevenuePage extends StatelessWidget {
  const DriverRevenuePage({super.key, required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    final service = RevenueService();

    return SafeArea(
      child: StreamBuilder<List<RequestModel>>(
        stream: service.watchCompletedDriverRequests(driverId),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <RequestModel>[];
          final summary = service.summarize(requests);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              _RevenueHeader(summary: summary),
              const SizedBox(height: 16),
              const Text(
                'Historique paiements',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
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
                const _RevenueMessage('Aucun revenu pour le moment.')
              else
                for (final request in requests) _RevenueTile(request: request),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueHeader extends StatelessWidget {
  const _RevenueHeader({required this.summary});

  final RevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MainBalance(summary.availableBalance),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Revenus',
                value: '${summary.totalRevenue} FCFA',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Commission MotoFix',
                value: '${summary.commission} FCFA',
                icon: Icons.percent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricCard(
          title: 'Courses du jour',
          value: summary.completedTrips.toString(),
          icon: Icons.route_outlined,
        ),
      ],
    );
  }
}

class _MainBalance extends StatelessWidget {
  const _MainBalance(this.balance);

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: MotoFixUi.gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '$balance FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(icon, color: MotoFixUi.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MotoFixUi.textSoft),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueTile extends StatelessWidget {
  const _RevenueTile({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final date = request.createdAt == null
        ? ''
        : DateFormat('dd MMM yyyy - HH:mm').format(request.createdAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          Icon(
            request.isTaxi ? Icons.local_taxi : Icons.build_circle_outlined,
            color: MotoFixUi.orange,
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
                Text(date, style: const TextStyle(color: MotoFixUi.textSoft)),
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

class _RevenueMessage extends StatelessWidget {
  const _RevenueMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: MotoFixUi.textSoft),
      ),
    );
  }
}
