import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key, this.requestId});

  final String? requestId;

  @override
  Widget build(BuildContext context) {
    final id = requestId;
    if (id == null) {
      return MotoFixUi.page(
        appBar: MotoFixUi.appBar('En route vers vous'),
        child: const _MapBody(),
      );
    }

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('En route vers vous'),
      child: StreamBuilder<RequestModel?>(
        stream: RequestService().watchRequest(id),
        builder: (context, snapshot) {
          return _MapBody(request: snapshot.data);
        },
      ),
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({this.request});

  final RequestModel? request;

  @override
  Widget build(BuildContext context) {
    final driverName = request?.driverName.trim().isNotEmpty == true
        ? request!.driverName
        : 'Issa';
    final driverVehicle = request?.driverVehicle.trim().isNotEmpty == true
        ? request!.driverVehicle
        : 'TVS Apache';
    final driverPlate = request?.driverPlate.trim().isNotEmpty == true
        ? request!.driverPlate
        : '1234 NN 75';

    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: MapMockPainter()),
        ),
        Positioned(
          top: 86,
          right: 52,
          child: _AvatarMarker(
            color: MotoFixUi.orange,
            icon: Icons.person,
          ),
        ),
        const Positioned(
          top: 205,
          left: 95,
          child: _AvatarMarker(
            color: Colors.white,
            icon: Icons.person,
            darkIcon: true,
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 22,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MotoFixUi.bg.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 27,
                      backgroundColor: MotoFixUi.orange2,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 15),
                              SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(color: MotoFixUi.textSoft),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      driverPlate,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Moto',
                        style: TextStyle(color: MotoFixUi.textSoft),
                      ),
                    ),
                    Text(
                      driverVehicle,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Arrivee prevue dans 5 min',
                        style: TextStyle(color: MotoFixUi.textSoft),
                      ),
                    ),
                    _RoundAction(icon: Icons.phone, onTap: () {}),
                    const SizedBox(width: 10),
                    _RoundAction(icon: Icons.message, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarMarker extends StatelessWidget {
  const _AvatarMarker({
    required this.color,
    required this.icon,
    this.darkIcon = false,
  });

  final Color color;
  final IconData icon;
  final bool darkIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(
        icon,
        color: darkIcon ? MotoFixUi.bg : Colors.white,
        size: 20,
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFF2A8B35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}
