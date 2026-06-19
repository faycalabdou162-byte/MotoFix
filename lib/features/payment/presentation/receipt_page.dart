import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/feature_models.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_button.dart';

/// Payment receipt screen — shown after successful payment.
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({
    super.key,
    required this.payment,
    this.requestType,
    this.pickupAddress,
  });

  final PaymentModel payment;
  final String? requestType;
  final String? pickupAddress;

  @override
  Widget build(BuildContext context) {
    final date = payment.createdAt ?? DateTime.now();
    final ref = payment.id.length > 8
        ? payment.id.substring(0, 8).toUpperCase()
        : payment.id.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Reçu de paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              payment.status == PaymentStatus.paid
                  ? 'Paiement confirmé'
                  : PaymentStatus.label(payment.status),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptRow(label: 'Référence', value: '#$ref'),
                  _ReceiptRow(
                    label: 'Montant',
                    value: AppFormatters.currency(payment.amount),
                    highlight: true,
                  ),
                  _ReceiptRow(
                    label: 'Méthode',
                    value: PaymentMethod.label(payment.method),
                  ),
                  if (payment.phone.isNotEmpty)
                    _ReceiptRow(label: 'Téléphone', value: payment.phone),
                  if (requestType != null)
                    _ReceiptRow(label: 'Service', value: requestType!),
                  if (pickupAddress != null && pickupAddress!.isNotEmpty)
                    _ReceiptRow(label: 'Lieu', value: pickupAddress!),
                  _ReceiptRow(
                    label: 'Date',
                    value: DateFormat('dd/MM/yyyy HH:mm').format(date),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: 'Partager le reçu',
              icon: Icons.share_rounded,
              outlined: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partage bientôt disponible'),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumButton(
              label: 'Retour à l\'accueil',
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                fontSize: highlight ? 18 : 14,
                color: highlight ? AppColors.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
