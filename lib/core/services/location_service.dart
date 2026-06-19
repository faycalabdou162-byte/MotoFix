import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/app_exceptions.dart';

/// Centralized GPS / location utilities for client & mechanic tracking.
class LocationService {
  Future<void> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'Activez la localisation sur votre téléphone.',
        code: 'location_disabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permission de localisation refusée.',
        code: 'permission_denied',
      );
    }
  }

  Future<Position> currentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<GeoPoint?> currentGeoPoint() async {
    try {
      final position = await currentPosition();
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Stream<Position> positionStream({int distanceFilterMeters = 15}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// Haversine distance in kilometers.
  static double distanceKm(GeoPoint from, GeoPoint to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000;
  }

  /// Rough ETA assuming average urban speed ~25 km/h for moto.
  static int etaMinutes(GeoPoint from, GeoPoint to) {
    final km = distanceKm(from, to);
    if (km <= 0.05) return 1;
    return (km / 25 * 60).ceil().clamp(1, 120);
  }
}
