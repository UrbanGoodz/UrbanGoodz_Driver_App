import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/models/capability_model.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

import 'support/fakes.dart';

void main() {
  group('CapabilityAllowedValues', () {
    test('accepts associative vehicle types and the work_types API key', () {
      final allowed = CapabilityAllowedValues.fromJson({
        'vehicle_types': {'car': 'Car', 'cargo_van': 'Cargo Van'},
        'capability_tags': ['retail_delivery', 'medical_courier'],
        'work_types': ['retail_delivery', 'package_routes'],
        'availability_preferences': [
          'standard',
          'weekdays',
          'weekends',
          'evenings',
          'overnight',
          'on_demand',
        ],
      });

      expect(allowed.vehicleTypes, ['car', 'cargo_van']);
      expect(allowed.capabilityTags, ['retail_delivery', 'medical_courier']);
      expect(allowed.preferredWorkTypes, ['retail_delivery', 'package_routes']);
      expect(allowed.availabilityPreferences, [
        'standard',
        'weekdays',
        'weekends',
        'evenings',
        'overnight',
        'on_demand',
      ]);
    });

    test(
      'keeps compatibility with array vehicle types and legacy work key',
      () {
        final allowed = CapabilityAllowedValues.fromJson({
          'vehicle_types': ['car', 'suv'],
          'preferred_work_types': ['business_courier'],
        });

        expect(allowed.vehicleTypes, ['car', 'suv']);
        expect(allowed.preferredWorkTypes, ['business_courier']);
      },
    );
  });

  group('service zones', () {
    test(
      'parses the live endpoint array and excludes inactive zones',
      () async {
        final client = FakeApiClient()
          ..stub(
            ApiConfig.zoneList,
            const Response(
              statusCode: 200,
              body: [
                {
                  'id': 2,
                  'name': 'Houston',
                  'display_name': 'Greater Houston Area',
                  'status': 1,
                },
                {'id': '3', 'name': 'Greater Dallas Area', 'status': '1'},
                {'id': 4, 'name': 'Inactive', 'status': 0},
              ],
            ),
          );
        final service = DriverApiService(client: client);

        final zones = await service.getServiceZones();

        expect(client.calls.single.method, 'GET');
        expect(client.calls.single.path, ApiConfig.zoneList);
        expect(zones.map((zone) => zone.id), [2, 3]);
        expect(zones.map((zone) => zone.name), [
          'Greater Houston Area',
          'Greater Dallas Area',
        ]);
      },
    );
  });
}
