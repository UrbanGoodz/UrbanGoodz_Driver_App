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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDriverApiService api;
  late DriverAuthController auth;

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    api = FakeDriverApiService(client: FakeApiClient());
    auth = DriverAuthController();
    Get.put<DriverAuthController>(auth);
    Get.put<ApiClient>(FakeApiClient());
    Get.put<DriverApiService>(api);
  });

  tearDown(Get.reset);

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const DriverOnboardingScreen(),
      ),
    );
    await tester.pump();
  }

  Future<void> submit(
    WidgetTester tester, {
    String identifier = '+15550101',
    String password = 'realpassword',
  }) async {
    await tester.enterText(
      find.byKey(const Key('driver_login_identifier')),
      identifier,
    );
    await tester.enterText(
      find.byKey(const Key('driver_login_password')),
      password,
    );
    await tester.tap(find.byKey(const Key('driver_login_submit')));
    await tester.pump();
    await tester.pump();
  }

  group('authentication bypasses are gone', () {
    testWidgets('no OTP entry, no OTP verify, no phone-code tab', (tester) async {
      await pumpLogin(tester);

      // These controls previously faked "code sent", accepted any 4+ digit
      // code, and could mint a 'demo_driver_token_verified' session.
      expect(find.byKey(const Key('driver_otp_request')), findsNothing);
      expect(find.byKey(const Key('driver_otp_code')), findsNothing);
      expect(find.byKey(const Key('driver_otp_verify')), findsNothing);
      expect(find.byKey(const Key('driver_otp_resend')), findsNothing);
      expect(find.textContaining('OTP'), findsNothing);
      expect(find.text('Phone OTP'), findsNothing);
    });

    testWidgets('password reset no longer claims a code was sent', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.byKey(const Key('driver_forgot_password')));
      await tester.pumpAndSettle();

      expect(find.textContaining('not available yet'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsNothing);
      expect(find.text('Reset Code Sent'), findsNothing);
    });

    testWidgets('a failed login never sets a session', (tester) async {
      api.loginError = ApiException(
        401,
        'Incorrect credential  please try again',
        code: 'auth-001',
      );

      await pumpLogin(tester);
      await submit(tester);

      expect(auth.isLoggedIn.value, isFalse);
      expect(auth.token.value, isEmpty);
      expect(find.byKey(const Key('driver_dashboard')), findsNothing);
    });
  });

  group('login outcomes', () {
    testWidgets('invalid credentials show an actionable message', (tester) async {
      api.loginError = ApiException(
        401,
        'Incorrect credential  please try again',
        code: 'auth-001',
      );

      await pumpLogin(tester);
      await submit(tester);

      expect(find.byKey(const Key('driver_auth_error')), findsOneWidget);
      expect(
        find.textContaining('Incorrect phone/email or password'),
        findsOneWidget,
      );
    });

    testWidgets('rate limiting tells the driver how long to wait', (tester) async {
      api.loginError = ApiException(
        429,
        'Too Many Attempts.',
        retryAfterSeconds: 22,
      );

      await pumpLogin(tester);
      await submit(tester);

      expect(find.textContaining('22 seconds'), findsOneWidget);
    });

    testWidgets('an account the backend refuses is reported verbatim',
        (tester) async {
      // Pending-approval / suspended / rejected all arrive through this same
      // envelope, so the server's own wording is shown rather than guessed.
      api.loginError = ApiException(
        401,
        'Your account is under review. Please wait for approval.',
        code: 'auth-002',
      );

      await pumpLogin(tester);
      await submit(tester);

      expect(
        find.textContaining('Your account is under review'),
        findsOneWidget,
      );
      expect(auth.isLoggedIn.value, isFalse);
    });

    testWidgets('a 200 with no token is refused rather than faked', (tester) async {
      api.loginResult = {'message': 'ok'};

      await pumpLogin(tester);
      await submit(tester);

      expect(auth.isLoggedIn.value, isFalse);
      expect(auth.token.value, isEmpty);
      expect(find.textContaining('did not return a session token'), findsOneWidget);
    });

    testWidgets('an account rejected at profile check does not keep the token',
        (tester) async {
      api.loginResult = {'token': 'fresh-token'};
      api.profileError = ApiException(
        401,
        'Your driver account has been suspended.',
      );

      await pumpLogin(tester);
      await submit(tester);

      expect(auth.token.value, isEmpty,
          reason: 'credentials were valid but the account cannot be used');
      expect(auth.isLoggedIn.value, isFalse);
      expect(find.textContaining('suspended'), findsOneWidget);
    });

    testWidgets('a network failure is reported, not swallowed', (tester) async {
      api.loginError = Exception('SocketException: failed host lookup');

      await pumpLogin(tester);
      await submit(tester);

      expect(find.textContaining('Unable to reach Urban Goodz'), findsOneWidget);
      expect(auth.isLoggedIn.value, isFalse);
    });

    testWidgets('validation blocks submission with empty fields', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.byKey(const Key('driver_login_submit')));
      await tester.pump();

      expect(find.text('Phone number or email required'), findsOneWidget);
      expect(auth.isLoggedIn.value, isFalse);
    });
  });

  testWidgets('an expired session is explained on return to login', (tester) async {
    auth.sessionExpiredNotice.value = 'Your session has expired. Please sign in again.';

    await pumpLogin(tester);

    expect(find.textContaining('session has expired'), findsOneWidget);
    expect(auth.sessionExpiredNotice.value, isEmpty,
        reason: 'the notice is consumed so it does not reappear later');
  });
}
