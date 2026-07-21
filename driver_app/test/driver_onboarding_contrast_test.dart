import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/screens/driver_onboarding_screen.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put(DriverAuthController());
    Get.put(ApiClient());
    Get.put(DriverApiService());
  });

  tearDown(Get.reset);

  testWidgets('Driver onboarding sign-in screen renders with high-contrast text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const DriverOnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main title & subtitle
    expect(find.text('Urban Goodz Driver'), findsOneWidget);
    expect(find.text('Sign in with your driver account'), findsOneWidget);

    // Verify subtitle text uses dark high contrast color (not accent yellow)
    final Text subtitleText = tester.widget(find.text('Sign in with your driver account'));
    expect(subtitleText.style?.color, AppTheme.dark);

    // Verify input fields & action buttons are visible
    expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'SIGN IN'), findsOneWidget);
    expect(find.text('Apply to Join as a Driver'), findsOneWidget);

    // Test validation state
    await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
  });
}
