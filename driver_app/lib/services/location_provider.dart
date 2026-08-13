import 'package:geolocator/geolocator.dart';

/// A single GPS fix, with the time it was taken so the app can tell a fresh
/// fix from a stale one instead of reporting whatever it last saw.
class DriverPosition {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyMeters;

  const DriverPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
  });
}

enum LocationPermissionState {
  granted,

  /// Driver denied this time; asking again is allowed.
  denied,

  /// Driver denied permanently — only Settings can re-enable it.
  deniedForever,

  /// Device location services are switched off entirely.
  serviceDisabled,
}

/// Seam between the driver app and the platform GPS. Widget tests inject a
/// fake implementation; production uses [GeolocatorLocationProvider].
abstract class LocationProvider {
  Future<LocationPermissionState> ensurePermission();

  /// Emits a fix whenever the driver has moved [distanceFilterMeters].
  Stream<DriverPosition> positionStream({int distanceFilterMeters});

  Future<DriverPosition?> currentPosition();
}

class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<LocationPermissionState> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionState.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionState.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.denied;
    }
  }

  @override
  Stream<DriverPosition> positionStream({int distanceFilterMeters = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map(_toDriverPosition);
  }

  @override
  Future<DriverPosition?> currentPosition() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return _toDriverPosition(p);
    } catch (_) {
      return null;
    }
  }

  DriverPosition _toDriverPosition(Position p) => DriverPosition(
    latitude: p.latitude,
    longitude: p.longitude,
    timestamp: p.timestamp,
    accuracyMeters: p.accuracy,
  );
}
