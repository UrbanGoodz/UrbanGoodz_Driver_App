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
    expect(find.text('Driver Login'), findsOneWidget);

    // Verify subtitle text uses dark high contrast color
    final Text titleText = tester.widget(find.text('Urban Goodz Driver'));
    expect(titleText.style?.color, AppTheme.dark);

    // Verify input fields & action buttons are visible
    expect(find.text('Phone Number / Email'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Test validation state
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
  });
}
