import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/screens/driver_onboarding_screen.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

import 'support/fakes.dart';

// This suite previously asserted on strings the login screen has never
// rendered ('Urban Goodz Driver', 'Driver Login', 'Phone Number / Email',
// 'Create Account', 'Required'). It failed at the recovery base commit
// c633cec too — 'Urban Goodz Driver' existed there only as a hardcoded
// fallback *name* inside the OTP login bypass, not as visible text. It is
// rewritten here against the screen that actually ships.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put(DriverAuthController());
    Get.put<ApiClient>(FakeApiClient());
    Get.put<DriverApiService>(FakeDriverApiService(client: FakeApiClient()));
  });

  tearDown(Get.reset);

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const DriverOnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the brand header in high-contrast text', (tester) async {
    await pumpLogin(tester);

    expect(find.text('URBAN GOODZ'), findsOneWidget);
    expect(find.text('DRIVER PARTNER LOGISTICS'), findsOneWidget);

    final Text title = tester.widget(find.text('URBAN GOODZ'));
    expect(title.style?.color, AppTheme.dark);
  });

  testWidgets('shows the single supported sign-in form', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Phone Number or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Exactly two inputs: identifier and password. Any more would mean an
    // unsupported auth path (such as OTP) has crept back in.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.text('Apply as New Driver'), findsOneWidget);
  });

  testWidgets('blocks submission and names the missing fields', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('driver_login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Phone number or email required'), findsOneWidget);
    expect(find.text('Minimum 6 characters required'), findsOneWidget);
  });

  testWidgets('lays out without overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpLogin(tester);

    expect(tester.takeException(), isNull);
  });
}
