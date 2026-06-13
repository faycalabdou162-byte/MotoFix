import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/motofix_ui.dart';
import '../models/feature_models.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key, required this.config});

  final MaintenanceConfig config;

  @override
  Widget build(BuildContext context) {
    final title = config.forceUpdate
        ? 'Mise a jour obligatoire'
        : config.serverAvailable
        ? 'Maintenance'
        : 'Serveur indisponible';

    return MotoFixUi.page(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: MotoFixUi.panelDecoration(radius: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      config.forceUpdate
                          ? Icons.system_update_alt
                          : Icons.construction_outlined,
                      color: MotoFixUi.orange,
                      size: 54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      config.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MotoFixUi.textSoft,
                        height: 1.45,
                      ),
                    ),
                    if (config.updateUrl.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      MotoFixButton(
                        label: 'Copier le lien de mise a jour',
                        icon: Icons.copy,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: config.updateUrl),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lien copie')),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
