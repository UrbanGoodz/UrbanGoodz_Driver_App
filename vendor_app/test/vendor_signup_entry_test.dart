import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/screens/vendor_onboarding_screen.dart';
import 'package:urban_goodz_vendor/screens/vendor_registration_screen.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final api = VendorApiClient();
    final repo = VendorRepository(api);
    Get.put(api);
    Get.put(repo);
    Get.put(VendorAuthController(repo, api));
  });

  tearDown(Get.reset);

  testWidgets('Vendor onboarding renders sign-up entry and routes to VendorRegistrationScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const VendorOnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main onboarding screen elements
    expect(find.text('Urban Goodz Vendor'), findsOneWidget);
    expect(find.text('Vendor Login'), findsOneWidget);

    // Verify visible sign-up entry button
    expect(find.text('Create Account'), findsOneWidget);

    // Ensure visible and tap sign-up entry button
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Verify route opened VendorRegistrationScreen
    expect(find.byType(VendorRegistrationScreen), findsOneWidget);
    expect(find.text('Create Vendor Account'), findsOneWidget);
    expect(find.text('SUBMIT VENDOR APPLICATION'), findsOneWidget);

    // Scroll and tap back button to return to login
    await tester.ensureVisible(find.text('Already have an account? Sign In'));
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(VendorOnboardingScreen), findsOneWidget);
  });
}
