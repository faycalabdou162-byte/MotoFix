import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../services/request_service.dart';
import '../request/request_page.dart';

class TaxiPage extends StatefulWidget {
  const TaxiPage({super.key});

  @override
  State<TaxiPage> createState() => _TaxiPageState();
}

class _TaxiPageState extends State<TaxiPage> {
  final TextEditingController _destinationController = TextEditingController();
  final RequestService _requestService = RequestService();
  bool _loading = false;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _sendTaxiRequest() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final requestId = await _requestService.createClientRequest(
        type: 'taxi',
        pickupAddress: 'Ma position actuelle - Niamey, Niger',
        destinationAddress: _destinationController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande taxi envoyee'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RequestPage(requestId: requestId)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envoi impossible: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Demande Taxi'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const ScooterScene(height: 170),
              const SizedBox(height: 18),
              const Text(
                'Commander un taxi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Un chauffeur recevra votre demande\net vous contactera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MotoFixUi.textSoft,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: MotoFixUi.panelDecoration(radius: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: MotoFixUi.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ma position actuelle',
                            style: TextStyle(
                              color: MotoFixUi.orange,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Niamey, Niger',
                            style: TextStyle(color: MotoFixUi.textSoft),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              MotoFixField(
                controller: _destinationController,
                hint: 'Destination ou repere (optionnel)',
                icon: Icons.flag_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendTaxiRequest(),
              ),
              const SizedBox(height: 28),
              MotoFixButton(
                label: 'Demander un taxi',
                loading: _loading,
                onPressed: _loading ? null : _sendTaxiRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
