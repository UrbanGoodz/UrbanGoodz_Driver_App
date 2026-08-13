import 'dart:async';

import 'package:urban_goodz_driver/services/location_provider.dart';

/// A GPS source under full test control.
class FakeLocationProvider implements LocationProvider {
  FakeLocationProvider({
    this.permission = LocationPermissionState.granted,
    this.fix,
  });

  LocationPermissionState permission;
  DriverPosition? fix;
  int permissionRequests = 0;

  final controller = StreamController<DriverPosition>.broadcast();

  @override
  Future<LocationPermissionState> ensurePermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<DriverPosition?> currentPosition() async => fix;

  @override
  Stream<DriverPosition> positionStream({int distanceFilterMeters = 25}) =>
      controller.stream;

  Future<void> dispose() => controller.close();
}

DriverPosition positionAt({
  double lat = 40.7128,
  double lng = -74.0060,
  DateTime? at,
}) => DriverPosition(
  latitude: lat,
  longitude: lng,
  timestamp: at ?? DateTime.now(),
  accuracyMeters: 8.0,
);
