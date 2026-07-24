import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/screens/dashboard_screen.dart';
import 'package:urban_goodz_vendor/screens/vendor_onboarding_screen.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';

/// Contract tests for POST auth/vendor/login.
///
/// These exercise the repository + API client against recorded responses
/// taken from VendorLoginController@login and storeSubscriptionCheck. They
/// deliberately do NOT construct VendorAuthController, which needs
/// SharedPreferences and Firebase plugin channels unavailable in a plain
/// unit-test binding; the state-mapping logic it wraps is asserted through
/// the error codes below.
///
/// Every HTTP-facing test injects a stub http.Client. Nothing in this file
/// touches the network: under TestWidgetsFlutterBinding a real HttpClient
/// answers 400 to everything, so a live request would prove nothing.
class _StubClient extends http.BaseClient {
  _StubClient(this.response);

  final http.Response response;
  final List<http.Request> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      request: request,
    );
  }

  Map<String, dynamic> get sentBody =>
      jsonDecode(requests.single.body) as Map<String, dynamic>;
}

http.Response _json(Map<String, Object?> body, int status) =>
    http.Response(jsonEncode(body), status);

http.Response _authError(String code, String message, int status) => _json({
  'errors': [
    {'code': code, 'message': message},
  ],
}, status);

VendorRepository _repo(_StubClient client) =>
    VendorRepository(VendorApiClient(client: client));

void main() {
  group('login request shape', () {
    test('posts email, password and vendor_type owner to the real path',
        () async {
      final client = _StubClient(
        _json({
          'token': 'a' * 120,
          'zone_wise_topic': 'zone_5_store',
          'module_type': 'grocery',
        }, 200),
      );

      final result = await _repo(client).login('store@vendor.test', 'Secret123');

      expect(client.requests.single.method, 'POST');
      expect(client.requests.single.url.path, endsWith('/auth/vendor/login'));
      expect(client.sentBody, {
        'email': 'store@vendor.test',
        'password': 'Secret123',
        'vendor_type': 'owner',
      });
      // Login carries no vendor/store payload - only these three fields.
      expect(result['token'], 'a' * 120);
      expect(result['zone_wise_topic'], 'zone_5_store');
      expect(result['module_type'], 'grocery');
      expect(result.containsKey('requires_subscription'), isFalse);
    });
  });

  group('account states (only codes the backend actually emits)', () {
    Future<VendorApiException> capture(http.Response response) async {
      try {
        await _repo(_StubClient(response)).login('a@b.test', 'Secret123');
        fail('expected VendorApiException');
      } on VendorApiException catch (e) {
        return e;
      }
    }

    test('auth-001 invalid credentials surfaces 401 + code', () async {
      final e = await capture(
        _authError('auth-001', 'Credential do not match, please try again', 401),
      );
      expect(e.statusCode, 401);
      expect((e.body as Map)['errors'][0]['code'], 'auth-001');
    });

    test('auth-002 pending approval surfaces 403 + code', () async {
      final e = await capture(
        _authError(
          'auth-002',
          'Your registration is not approved yet. You can login once admin approved the request',
          403,
        ),
      );
      expect(e.statusCode, 403);
      expect((e.body as Map)['errors'][0]['code'], 'auth-002');
    });

    test('store_inactive suspended surfaces 403 + code', () async {
      final e = await capture(
        _authError('store_inactive', 'Your account is suspended', 403),
      );
      expect(e.statusCode, 403);
      expect((e.body as Map)['errors'][0]['code'], 'store_inactive');
    });

    test('store_missing surfaces 403 + code', () async {
      final e = await capture(
        _authError('store_missing', 'No store is assigned to this vendor.', 403),
      );
      expect(e.statusCode, 403);
      expect((e.body as Map)['errors'][0]['code'], 'store_missing');
    });
  });

  group('subscription payload is not a session', () {
    test(
      'HTTP 200 {subscribed:{...}} is flagged, not returned as a login token',
      () async {
        // storeSubscriptionCheck returns 200 with an embedded token when
        // store_business_model == 'none'. Treating that as success would put
        // an unsubscribed vendor on the dashboard.
        final client = _StubClient(
          _json({
            'subscribed': {
              'store_id': 42,
              'token': 'b' * 120,
              'package_id': 7,
            },
          }, 200),
        );

        final result = await _repo(client).login('a@b.test', 'Secret123');

        expect(result['requires_subscription'], isTrue);
        expect(result['store_id'], 42);
      },
    );
  });

  // The sign-in screen is driven through a recording VendorAuthController, so
  // these assert what the widget actually executes rather than what any
  // comment claims. The removed bypass is a behavioural defect - the only
  // proof it is gone is that no credential reaches the dashboard without the
  // controller returning true.
  group('sign-in screen delegates authentication to the API', () {
    late _RecordingAuthController auth;
    late _RouteRecorder routes;

    Future<void> pumpLogin(WidgetTester tester, {required bool grant}) async {
      final api = VendorApiClient(client: _StubClient(_json({}, 200)));
      final repository = _FakeRepository(api);
      auth = _RecordingAuthController(repository, api, grant: grant);
      routes = _RouteRecorder();
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      Get.put<VendorApiClient>(api);
      Get.put<VendorRepository>(repository);
      Get.put<VendorAuthController>(auth);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          navigatorObservers: [routes],
          home: const VendorOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      routes.pushed.clear(); // drop the initial home route
    }

    Future<void> submit(
      WidgetTester tester, {
      String email = '  store@vendor.test  ',
      String password = 'Secret123',
    }) async {
      await tester.enterText(const Key('vendor_login_email').finder, email);
      await tester.enterText(
        const Key('vendor_login_password').finder,
        password,
      );
      await tester.tap(const Key('vendor_login_submit').finder);
      // idle() flushes the login future without pumping a frame, so the
      // navigation is observed through `routes` rather than laid out. The
      // dashboard's revenue chart divides by a zero maximum and sizes a bar to
      // NaN, which reports a RenderFlex overflow on any viewport; rendering it
      // here would fail these tests for an unrelated dashboard defect.
      await tester.idle();
    }

    tearDown(Get.reset);

    testWidgets('submitting credentials calls auth.login with the trimmed '
        'email and the typed password', (tester) async {
      await pumpLogin(tester, grant: true);

      await submit(tester);

      expect(auth.calls, [
        ('store@vendor.test', 'Secret123'),
      ]);
    });

    testWidgets('the dashboard opens when auth.login returns true',
        (tester) async {
      await pumpLogin(tester, grant: true);

      await submit(tester);

      final route = routes.pushed.single;
      expect(route, isA<GetPageRoute>());
      expect((route as GetPageRoute).page!(), isA<DashboardScreen>());
      // offAll: the sign-in route is torn down, so back cannot return to it.
      expect(routes.removedOrReplaced, isNotEmpty);
    });

    testWidgets('a rejected login opens nothing and shows the controller '
        'error', (tester) async {
      await pumpLogin(tester, grant: false);

      await submit(tester);
      await tester.pumpAndSettle();

      expect(auth.calls, hasLength(1));
      expect(routes.pushed, isEmpty);
      expect(find.byType(VendorOnboardingScreen), findsOneWidget);
      expect(const Key('vendor_auth_error').finder, findsOneWidget);
      expect(find.text(_RecordingAuthController.rejection), findsOneWidget);
    });

    testWidgets('an invalid form never reaches the API', (tester) async {
      await pumpLogin(tester, grant: true);

      await submit(tester, email: 'not-an-email', password: 'short');
      await tester.pumpAndSettle();

      expect(auth.calls, isEmpty);
      expect(routes.pushed, isEmpty);
      expect(find.byType(VendorOnboardingScreen), findsOneWidget);
    });
  });

  group('no mock authentication remains', () {
    // The guards below run against executable Dart only. Comments in
    // vendor_onboarding_screen.dart describe the bypass that was removed, so
    // matching raw file text would fail on the documentation instead of the
    // code.

    test('the comment stripper removes prose but keeps code', () {
      // Without this, every guard below could pass by stripping everything.
      const fixture = '''
// isLoggedIn = true
/* Future.delayed(const Duration(milliseconds: 700)); */
final hint = 'store@urbangoodz.com'; // vendor@urbangoodz.com
await auth.login(email, password);
''';
      final stripped = _executableCode(fixture);

      expect(stripped, isNot(contains('isLoggedIn = true')));
      expect(stripped, isNot(contains('Future.delayed')));
      expect(stripped, isNot(contains('vendor@urbangoodz.com')));
      expect(stripped, contains("final hint = 'store@urbangoodz.com';"));
      expect(stripped, contains('await auth.login(email, password);'));
    });

    test('phone-OTP sign-in is disabled', () {
      expect(phoneOtpLoginEnabled, isFalse);
    });

    testWidgets('the phone-OTP tab is not rendered while it is disabled',
        (tester) async {
      final api = VendorApiClient(client: _StubClient(_json({}, 200)));
      final repository = _FakeRepository(api);
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      Get.put<VendorApiClient>(api);
      Get.put<VendorRepository>(repository);
      Get.put<VendorAuthController>(
        _RecordingAuthController(repository, api, grant: false),
      );
      addTearDown(Get.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const VendorOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phone OTP'), findsNothing);
      expect(const Key('vendor_otp_request').finder, findsNothing);
      expect(const Key('vendor_otp_code').finder, findsNothing);
      expect(find.text('Email / Password'), findsOneWidget);
    });

    test('the sign-in screen contains no executable authentication bypass',
        () async {
      final code = _executableCode(
        await _readSource('lib/screens/vendor_onboarding_screen.dart'),
      );

      // Non-vacuity: the guard is reading real code, not an empty string.
      expect(code, contains('class _VendorOnboardingScreenState'));
      expect(code, contains('await auth.login('));

      // The bypass was: a fixed delay, then a local session flag, then a
      // canned identity - all without an API call.
      expect(code, isNot(contains('Future.delayed')));
      expect(code, isNot(contains('sleep(')));
      expect(
        code,
        isNot(matches(RegExp(r'isLoggedIn\s*(\.\s*value\s*)?=\s*true'))),
      );
      expect(code, isNot(contains('vendor@urbangoodz.com')));
      // No identity or session state is written from the screen at all; it is
      // owned by VendorAuthController and sourced from GET vendor/profile.
      expect(
        code,
        isNot(
          matches(
            RegExp(
              r'auth\s*\.\s*(isLoggedIn|approvalStatus|businessName|ownerName|'
              r'email|phone|city|businessType)\s*\.\s*value\s*=',
            ),
          ),
        ),
      );
      // Navigation to the dashboard is guarded by the controller's answer.
      expect(
        code,
        matches(
          RegExp(
            r'if\s*\(\s*succeeded\s*\)\s*\{\s*Get\.offAll\(\(\)\s*=>\s*'
            r'DashboardScreen\(\)\);',
          ),
        ),
      );
      expect('DashboardScreen('.allMatches(code).length, 1);
    });
  });
}

/// Records what the sign-in screen navigates to, so the dashboard hand-off can
/// be asserted without rendering the dashboard.
class _RouteRecorder extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];
  final List<Route<dynamic>> removedOrReplaced = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      removedOrReplaced.add(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) removedOrReplaced.add(oldRoute);
  }
}

/// A VendorAuthController whose login is the only thing the screen can use to
/// authenticate: it records the arguments and answers with a fixed verdict.
class _RecordingAuthController extends VendorAuthController {
  _RecordingAuthController(super.repository, super.api, {required this.grant});

  static const rejection = 'Credential do not match, please try again';

  final bool grant;
  final List<(String, String)> calls = [];

  @override
  Future<bool> login(String emailAddress, String password) async {
    calls.add((emailAddress, password));
    errorMessage.value = grant ? null : rejection;
    return grant;
  }
}

/// Serves the dashboard's initial fetch from memory so the success path can be
/// pumped without any HTTP.
class _FakeRepository extends VendorRepository {
  _FakeRepository(super.api);

  @override
  Future<Map<String, dynamic>> profile() async => {'stores': <String, dynamic>{}};

  @override
  Future<List<Map<String, dynamic>>> currentOrders() async => [];

  @override
  Future<Map<String, dynamic>> items({
    int limit = 100,
    int offset = 1,
    String? search,
  }) async => {'items': <Map<String, dynamic>>[]};

  @override
  Future<List<Map<String, dynamic>>> notifications() async => [];
}

extension on Key {
  Finder get finder => find.byKey(this);
}

/// Reads a source file relative to the package root (the test working
/// directory), so the guard assertions inspect the shipped code.
Future<String> _readSource(String relativePath) =>
    File(relativePath).readAsString();

/// Strips `//` and `/* */` comments while leaving string literals intact, so
/// the guards above assert on code the VM will actually run.
String _executableCode(String source) {
  final out = StringBuffer();
  String? quote;
  var i = 0;
  while (i < source.length) {
    final ch = source[i];
    final next = i + 1 < source.length ? source[i + 1] : '';
    if (quote != null) {
      if (ch == r'\' && next.isNotEmpty) {
        out.write(ch);
        out.write(next);
        i += 2;
        continue;
      }
      out.write(ch);
      if (ch == quote) quote = null;
      i++;
      continue;
    }
    if (ch == "'" || ch == '"') {
      quote = ch;
      out.write(ch);
      i++;
      continue;
    }
    if (ch == '/' && next == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
      continue;
    }
    if (ch == '/' && next == '*') {
      i += 2;
      while (i + 1 < source.length &&
          !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i += 2;
      continue;
    }
    out.write(ch);
    i++;
  }
  return out.toString();
}
