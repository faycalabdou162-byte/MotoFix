import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_gate.dart';
import '../core/theme/motofix_ui.dart';
import '../services/app_config_service.dart';
import 'maintenance_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: .94, end: 1).animate(_fade);
    _controller.forward();

    Timer(const Duration(milliseconds: 1200), _routeAfterSplash);
  }

  Future<void> _routeAfterSplash() async {
    Widget next = const AuthGate();

    try {
      final config = await AppConfigService().fetchMaintenanceConfig();
      if (config.blocksApp) {
        next = MaintenancePage(config: config);
      }
    } catch (_) {
      next = const AuthGate();
    }

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandMark(large: true),
                    SizedBox(height: 34),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: MotoFixUi.orange,
                        strokeWidth: 3,
                      ),
                    ),
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
