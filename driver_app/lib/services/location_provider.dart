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
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        // A pure distance filter sends nothing while the driver is stopped
        // (loading at a pickup, waiting at a light), so this also caps the
        // interval between fixes regardless of movement.
        intervalDuration: const Duration(seconds: 20),
        // Keeps the OS from suspending location updates when the screen is
        // off or another app is briefly in front, without needing the
        // "always" background-location permission. Per the plugin: this
        // raises priority, it does not guarantee survival if the activity
        // itself is destroyed (e.g. swiped from recents).
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Urban Goodz Driver is online',
          notificationText:
              'Sharing your location so dispatch can route deliveries to you.',
          notificationChannelName: 'Driver location sharing',
          enableWakeLock: true,
          setOngoing: true,
        ),
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
