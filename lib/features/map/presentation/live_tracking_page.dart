import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/request_model.dart';
import '../../../services/driver_service.dart';
import '../../../services/request_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_button.dart';

/// Live GPS tracking with Google Maps — replaces mock map when API key is set.
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final _locationService = LocationService();
  GoogleMapController? _mapController;
  StreamSubscription? _locationSub;

  @override
  void initState() {
    super.initState();
    _startClientLocationUpdates();
  }

  void _startClientLocationUpdates() {
    _locationSub = _locationService.positionStream().listen((_) {
      // Keeps client location fresh for distance recalculation.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng? _toLatLng(GeoPoint? point) {
    if (point == null) return null;
    return LatLng(point.latitude, point.longitude);
  }

  Set<Polyline> _buildRoute(RequestModel? request) {
    final pickup = _toLatLng(request?.pickupLocation);
    final driver = _toLatLng(request?.driverLocation);
    if (pickup == null || driver == null) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [driver, pickup],
        color: AppColors.primary,
        width: 5,
        geodesic: true,
      ),
    };
  }

  Set<Marker> _buildMarkers(RequestModel? request) {
    final markers = <Marker>{};
    final pickup = _toLatLng(request?.pickupLocation);
    final driver = _toLatLng(request?.driverLocation);

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Vous'),
        ),
      );
    }
    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: request?.driverName.isNotEmpty == true
                ? request!.driverName
                : 'Mécanicien',
          ),
        ),
      );
    }
    return markers;
  }

  void _fitBounds(RequestModel? request) {
    final pickup = _toLatLng(request?.pickupLocation);
    final driver = _toLatLng(request?.driverLocation);
    if (_mapController == null || pickup == null) return;

    if (driver == null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pickup, 15));
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup.latitude < driver.latitude ? pickup.latitude : driver.latitude,
        pickup.longitude < driver.longitude
            ? pickup.longitude
            : driver.longitude,
      ),
      northeast: LatLng(
        pickup.latitude > driver.latitude ? pickup.latitude : driver.latitude,
        pickup.longitude > driver.longitude
            ? pickup.longitude
            : driver.longitude,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi en direct')),
      body: StreamBuilder<RequestModel?>(
        stream: RequestService().watchRequest(widget.requestId),
        builder: (context, snapshot) {
          final request = snapshot.data;
          final pickup = _toLatLng(request?.pickupLocation);
          final initial = pickup ?? const LatLng(13.5127, 2.1124); // Niamey

          final eta = request?.pickupLocation != null &&
                  request?.driverLocation != null
              ? LocationService.etaMinutes(
                  request!.driverLocation!,
                  request.pickupLocation!,
                )
              : request?.durationMinutes ?? 0;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initial,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                polylines: _buildRoute(request),
                markers: _buildMarkers(request),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _fitBounds(request);
                },
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: GlassCard(
                  blur: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.engineering,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request?.driverName.isNotEmpty == true
                                      ? request!.driverName
                                      : 'Recherche en cours…',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  RequestStatus.label(
                                    request?.status ?? RequestStatus.pending,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (eta > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                AppFormatters.etaMinutes(eta),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (request?.status == RequestStatus.inProgress ||
                          request?.status == RequestStatus.accepted) ...[
                        const SizedBox(height: AppSpacing.md),
                        PremiumButton(
                          label: 'Actualiser position mécanicien',
                          icon: Icons.my_location,
                          onPressed: () async {
                            try {
                              await DriverService().syncCurrentLocation();
                            } catch (_) {}
                          },
                          height: 48,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}