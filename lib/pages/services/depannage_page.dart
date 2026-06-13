import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../services/request_service.dart';
import '../request/request_page.dart';

class DepannagePage extends StatefulWidget {
  const DepannagePage({super.key});

  @override
  State<DepannagePage> createState() => _DepannagePageState();
}

class _DepannagePageState extends State<DepannagePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final RequestService _requestService = RequestService();

  bool _loading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_loading) return;

    final text = _descriptionController.text.trim();

    if (text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez decrire votre panne.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final requestId = await _requestService.createClientRequest(
        type: 'depannage',
        description: text,
        pickupAddress: _addressController.text.trim().isEmpty
            ? 'Niamey, Niger'
            : _addressController.text.trim(),
      );

      if (!mounted) return;

      _descriptionController.clear();
      _addressController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande envoyee avec succes'),
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
      appBar: MotoFixUi.appBar('Demande Depannage'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 170,
                      height: 95,
                      child: CustomPaint(
                        painter: MotoLinePainter(color: Color(0xFF7D72D9)),
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.72,
                      child: const Icon(
                        Icons.build,
                        color: Color(0xFFC6BDFE),
                        size: 78,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Decrivez votre panne',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ajoutez un repere ou quartier\npour aider le reparateur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MotoFixUi.textSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              MotoFixField(
                controller: _addressController,
                hint: 'Quartier ou repere',
                icon: Icons.location_on_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              MotoFixField(
                controller: _descriptionController,
                hint: 'Ex : Moto en panne\na Yantala pres du marche...',
                icon: null,
                minLines: 6,
                maxLines: 7,
              ),
              const SizedBox(height: 28),
              MotoFixButton(
                label: 'Envoyer la demande',
                loading: _loading,
                onPressed: _loading ? null : _sendRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
