import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/screens/vendor_onboarding_screen.dart';
import 'package:urban_goodz_vendor/screens/vendor_registration_screen.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';

/// Never reaches the network: under TestWidgetsFlutterBinding a real
/// HttpClient answers 400 to every request, so the API client is built over a
/// stub.
class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({}))),
        200,
        request: request,
      );
}

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final api = VendorApiClient(client: _OfflineClient());
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

    // Identify the screen by its stable key, not by branding copy: the
    // heading is Urban Goodz marketing text and changes independently of the
    // sign-up entry point this test covers.
    expect(find.byKey(const Key('vendor_login_screen')), findsOneWidget);

    // Verify visible sign-up entry button
    final createAccount = find.byKey(const Key('vendor_create_account'));
    expect(createAccount, findsOneWidget);

    // Ensure visible and tap sign-up entry button
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    // Verify route opened VendorRegistrationScreen
    expect(find.byType(VendorRegistrationScreen), findsOneWidget);
    expect(find.byKey(const Key('vendor_login_screen')), findsNothing);
    expect(find.text('SUBMIT VENDOR APPLICATION'), findsOneWidget);

    // Scroll and tap back button to return to login
    await tester.ensureVisible(find.text('Already have an account? Sign In'));
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(VendorOnboardingScreen), findsOneWidget);
    expect(find.byKey(const Key('vendor_login_screen')), findsOneWidget);
  });
}
