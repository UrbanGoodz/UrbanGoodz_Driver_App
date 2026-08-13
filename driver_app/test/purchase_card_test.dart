import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/controllers/purchase_card_controller.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';
import 'package:urban_goodz_driver/models/purchase_card_model.dart';
import 'package:urban_goodz_driver/screens/purchase_card_screen.dart';
import 'package:urban_goodz_driver/screens/secure_card_reveal_screen.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

import 'support/fakes.dart';

/// Order Anywhere purchase-card coverage for the Driver app.
///
/// The provider is not configured in this build, so the tests that would prove
/// a real card works — PAN reveal against Stripe, merchant authorization,
/// provider reconciliation — are deliberately absent. What is covered is that
/// the app tells the truth in every state the backend can currently produce,
/// and refuses everything it is not entitled to do.
void main() {
  const requestId = 4321;
  final cardPath =
      '${ApiConfig.driverApiPrefix}/order-anywhere/$requestId/purchase-card';
  final revealPath = '$cardPath/secure-reveal';
  final receiptPath = '$cardPath/receipt';
  final failurePath = '$cardPath/failure';

  late FakeApiClient client;
  late DriverApiService api;

  setUp(() {
    client = FakeApiClient();
    api = DriverApiService(client: client);
  });

  tearDown(Get.reset);

  /// The backend's no-card envelope: `data` is null and the meaningful fields
  /// sit at the top level.
  Response noCardResponse({
    String workflow = 'awaiting_provider_configuration',
    String provider = 'not_configured',
  }) => Response(
    statusCode: 200,
    body: {
      'success': true,
      'data': null,
      'message': 'No active purchase card for this order.',
      'card_status': 'none',
      'workflow_status': workflow,
      'provider_configuration_status': provider,
    },
  );

  /// The backend's card envelope: everything nested under `data`.
  Response cardResponse(Map<String, dynamic> overrides) => Response(
    statusCode: 200,
    body: {
      'success': true,
      'data': {
        'card_status': 'issued',
        'card_status_label': 'Issued',
        'provider': 'stripe_issuing',
        'spending_limit': '120.00',
        'remaining_balance': '45.50',
        'currency': 'USD',
        'last4': '4242',
        'expires_at': '2027-01-31T00:00:00.000Z',
        'merchant_name': 'Corner Market',
        'secure_reveal_available': true,
        'receipt_submitted': false,
        'receipt_total': null,
        'failure_category': null,
        'provider_configuration_status': 'configured',
        'workflow_status': 'card_available',
        'instructions': 'Card is ready for use.',
        ...overrides,
      },
    },
  );

  Future<PurchaseCardController> loadedController(Response response) async {
    client.stub(cardPath, response, times: 20);
    final controller = PurchaseCardController(requestId: requestId, api: api);
    await controller.refreshCard();
    return controller;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    PurchaseCardController controller,
  ) async {
    // The screen is a lazy ListView, so a phone-sized surface leaves the lower
    // sections unbuilt and invisible to the finders. A tall surface renders
    // the whole page in one pass.
    await tester.binding.setSurfaceSize(const Size(1000, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PurchaseCardScreen(
          requestId: requestId,
          controllerOverride: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ------------------------------------------------------------------
  // 1-2. Navigation reachability and scoping
  // ------------------------------------------------------------------

  group('navigation', () {
    BusinessJobModel job({
      required String type,
      String status = 'assigned',
    }) => BusinessJobModel.fromJson({
      'job_id': requestId,
      'job_number': 'OA-1',
      'job_type': type,
      'status': status,
      'pickup': <String, dynamic>{},
      'dropoff': <String, dynamic>{},
    });

    test('1. assigned Order Anywhere work exposes the purchase card', () {
      expect(job(type: 'order_anywhere').showsPurchaseCard, isTrue);
    });

    test('2. other job types never expose the purchase card', () {
      expect(job(type: 'business_courier').showsPurchaseCard, isFalse);
      expect(job(type: 'dedicated_route').showsPurchaseCard, isFalse);
    });

    test('2b. cancelled or failed Order Anywhere work hides the card', () {
      // The backend refuses card actions on these with a 422, so offering the
      // section would only walk the driver into an error.
      expect(job(type: 'order_anywhere', status: 'cancelled').showsPurchaseCard,
          isFalse);
      expect(job(type: 'order_anywhere', status: 'failed').showsPurchaseCard,
          isFalse);
    });
  });

  // ------------------------------------------------------------------
  // 3-7, 13-15, 20-23. Lifecycle states
  // ------------------------------------------------------------------

  group('lifecycle states', () {
    test('3. awaiting_customer_payment', () async {
      final c = await loadedController(
        noCardResponse(
          workflow: 'awaiting_customer_payment',
          provider: 'configured',
        ),
      );
      expect(c.state.value!.lifecycle,
          CardLifecycleState.awaitingCustomerPayment);
      expect(c.state.value!.canReveal, isFalse);
    });

    test('4. awaiting_driver_assignment', () async {
      final c = await loadedController(
        noCardResponse(
          workflow: 'awaiting_driver_assignment',
          provider: 'configured',
        ),
      );
      expect(c.state.value!.lifecycle,
          CardLifecycleState.awaitingDriverAssignment);
      expect(c.state.value!.canReportFailure, isFalse);
    });

    testWidgets('5. awaiting_provider_configuration renders the exact copy',
        (tester) async {
      final c = await loadedController(noCardResponse());
      await pumpScreen(tester, c);

      expect(
        find.byKey(const Key('card_state_awaiting_provider_configuration')),
        findsOneWidget,
      );
      expect(find.text('Provider not configured yet.'), findsOneWidget);
      expect(
        find.textContaining(
          'issued automatically when card services become available',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('No action is required from you'),
        findsOneWidget,
      );
    });

    test('6. issuance_pending', () async {
      final c = await loadedController(
        noCardResponse(workflow: 'issuance_pending', provider: 'configured'),
      );
      expect(c.state.value!.lifecycle, CardLifecycleState.issuancePending);
      expect(c.state.value!.canReveal, isFalse);
    });

    test('7. card_available exposes reveal and real figures', () async {
      final c = await loadedController(cardResponse({}));
      final s = c.state.value!;
      expect(s.lifecycle, CardLifecycleState.cardAvailable);
      expect(s.canReveal, isTrue);
      expect(s.approvedLimit.display, r'$120.00');
      expect(s.remaining.display, r'$45.50');
      expect(s.amountUsed.display, r'$74.50');
    });

    test('13. canceled card blocks reveal (both spellings)', () async {
      for (final wire in ['canceled', 'cancelled']) {
        final c = await loadedController(
          cardResponse({'workflow_status': wire, 'card_status': 'cancelled'}),
        );
        expect(c.state.value!.lifecycle, CardLifecycleState.canceled);
        expect(c.state.value!.canReveal, isFalse);
        expect(c.state.value!.canUploadReceipt, isFalse);
      }
    });

    test('14. frozen card blocks reveal and receipt', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'frozen', 'card_status': 'frozen'}),
      );
      expect(c.state.value!.lifecycle, CardLifecycleState.frozen);
      expect(c.state.value!.canReveal, isFalse);
      expect(c.state.value!.canUploadReceipt, isFalse);
    });

    test('15. completed purchase allows receipt but not reveal', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'purchase_completed'}),
      );
      expect(c.state.value!.lifecycle, CardLifecycleState.purchaseCompleted);
      expect(c.state.value!.canReveal, isFalse);
      expect(c.state.value!.canUploadReceipt, isTrue);
    });

    test('20. reconciliation_pending', () async {
      final c = await loadedController(
        cardResponse({
          'workflow_status': 'reconciliation_pending',
          'receipt_submitted': true,
          'receipt_total': '74.50',
        }),
      );
      final s = c.state.value!;
      expect(s.lifecycle, CardLifecycleState.reconciliationPending);
      expect(s.receiptSubmitted, isTrue);
      expect(s.receiptTotal.display, r'$74.50');
    });

    test('21. reconciled is terminal', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'reconciled'}),
      );
      final s = c.state.value!;
      expect(s.lifecycle, CardLifecycleState.reconciled);
      expect(s.lifecycle.isTerminal, isTrue);
      expect(s.canReveal, isFalse);
      expect(s.canReportFailure, isFalse);
    });

    testWidgets('22. support_required offers a report path', (tester) async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'support_required'}),
      );
      await pumpScreen(tester, c);
      expect(find.byKey(const Key('card_state_support_required')),
          findsOneWidget);
      expect(find.byKey(const Key('report_failure')), findsOneWidget);
    });

    testWidgets('23. an unknown state fails safe to the support state',
        (tester) async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'quantum_superposition'}),
      );
      final s = c.state.value!;
      expect(s.lifecycle, CardLifecycleState.unknown);
      expect(s.canReveal, isFalse);
      expect(s.canUploadReceipt, isFalse);

      await pumpScreen(tester, c);
      expect(find.text('Support needed'), findsOneWidget);
    });

    test('every required lifecycle state parses to a distinct value', () {
      const required = [
        'awaiting_customer_payment',
        'awaiting_driver_assignment',
        'awaiting_provider_configuration',
        'issuance_pending',
        'card_available',
        'secure_reveal_available',
        'purchase_authorized',
        'purchase_completed',
        'receipt_required',
        'reconciliation_pending',
        'reconciled',
        'frozen',
        'canceled',
        'expired',
        'issuance_failed',
        'support_required',
      ];
      for (final wire in required) {
        expect(
          CardLifecycleState.parse(wire),
          isNot(CardLifecycleState.unknown),
          reason: '$wire must be a recognised state',
        );
      }
    });
  });

  // ------------------------------------------------------------------
  // 8-12. Secure reveal
  // ------------------------------------------------------------------

  group('secure reveal', () {
    test('8. reveal launch requests a session and returns the URL', () async {
      final c = await loadedController(cardResponse({}));
      client.stub(
        revealPath,
        const Response(
          statusCode: 200,
          body: {
            'success': true,
            'data': {
              'reveal_url': 'https://admin.urbangoodzdelivery.com/x/tok',
              'expires_at': '2099-01-01T00:00:00.000Z',
            },
          },
        ),
      );

      final session = await c.startReveal();
      expect(session, isNotNull);
      expect(session!.revealUrl, startsWith('https://'));
      expect(
        client.calls.where((call) => call.path == revealPath).length,
        1,
      );
    });

    test('9. reveal is refused locally when the provider is unconfigured',
        () async {
      final c = await loadedController(noCardResponse());
      final session = await c.startReveal();

      expect(session, isNull);
      // The critical assertion: nothing was sent. A provider-unconfigured
      // build must not create placeholder reveal sessions server-side.
      expect(client.calls.any((call) => call.path == revealPath), isFalse);
    });

    test('9b. a non-https reveal URL is rejected', () {
      expect(
        CardRevealSession.fromJson({'reveal_url': 'http://insecure/x'}),
        isNull,
      );
      expect(CardRevealSession.fromJson({'reveal_url': ''}), isNull);
      expect(CardRevealSession.fromJson(const {}), isNull);
    });

    test('10. an already-expired session is refused', () async {
      final c = await loadedController(cardResponse({}));
      client.stub(
        revealPath,
        Response(
          statusCode: 200,
          body: {
            'success': true,
            'data': {
              'reveal_url': 'https://admin.urbangoodzdelivery.com/x/tok',
              'expires_at': DateTime.now()
                  .subtract(const Duration(minutes: 1))
                  .toIso8601String(),
            },
          },
        ),
      );

      expect(await c.startReveal(), isNull);
      expect(c.revealError.value, contains('expired'));
    });

    testWidgets('10b. an expired session shows the ended-session view',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecureCardRevealScreen(
            session: CardRevealSession(
              revealUrl: 'https://example.test/reveal',
              expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            webViewBuilder: () => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('secure_reveal_expired')), findsOneWidget);
      expect(find.byKey(const Key('secure_reveal_webview')), findsNothing);
    });

    testWidgets('11. backgrounding conceals the reveal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecureCardRevealScreen(
            session: CardRevealSession(
              revealUrl: 'https://example.test/reveal',
              expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            ),
            webViewBuilder: () => const Text('PROVIDER HOSTED PAGE'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('secure_reveal_webview')), findsOneWidget);

      // inactive fires before paused and covers the app-switcher snapshot.
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      await tester.pump();

      expect(find.byKey(const Key('secure_reveal_concealed')), findsOneWidget);
      expect(find.byKey(const Key('secure_reveal_webview')), findsNothing);
      expect(find.text('PROVIDER HOSTED PAGE'), findsNothing);
    });

    testWidgets('11b. resuming does not silently restore the session',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecureCardRevealScreen(
            session: CardRevealSession(
              revealUrl: 'https://example.test/reveal',
              expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            ),
            webViewBuilder: () => const Text('PROVIDER HOSTED PAGE'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // The driver must ask again, which forces a fresh short-lived session.
      expect(find.byKey(const Key('secure_reveal_expired')), findsOneWidget);
      expect(find.text('PROVIDER HOSTED PAGE'), findsNothing);
    });

    test('12. a reassigned driver is refused by the backend and surfaced',
        () async {
      final c = await loadedController(cardResponse({}));
      client.queued.remove(revealPath);
      client.stub(
        revealPath,
        const Response(
          statusCode: 403,
          body: {
            'success': false,
            'message': 'You are not the currently assigned driver.',
          },
        ),
      );

      expect(await c.startReveal(), isNull);
      expect(c.revealError.value, contains('different driver'));
    });

    test('a reveal session never stringifies its URL', () {
      final session = CardRevealSession(
        revealUrl: 'https://example.test/secret-token-abc123',
        expiresAt: DateTime.now(),
      );
      expect(session.toString(), isNot(contains('secret-token-abc123')));
    });
  });

  // ------------------------------------------------------------------
  // 16-19. Receipt workflow
  // ------------------------------------------------------------------

  group('receipt workflow', () {
    late File receiptFile;

    setUp(() async {
      receiptFile = File(
        '${Directory.systemTemp.path}/ug_receipt_test.jpg',
      );
      await receiptFile.writeAsBytes(List<int>.filled(64, 7));
    });

    tearDown(() async {
      if (receiptFile.existsSync()) await receiptFile.delete();
    });

    testWidgets('16. receipt capture controls appear when a receipt is due',
        (tester) async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'receipt_required'}),
      );
      await pumpScreen(tester, c);

      expect(find.byKey(const Key('receipt_section')), findsOneWidget);
      expect(find.byKey(const Key('receipt_camera')), findsOneWidget);
      expect(find.byKey(const Key('receipt_gallery')), findsOneWidget);
    });

    test('17. receipt upload posts to this request only', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'receipt_required'}),
      );
      client.stub(
        receiptPath,
        const Response(
          statusCode: 200,
          body: {
            'success': true,
            'data': {'receipt_submitted': true, 'receipt_total': '31.20'},
          },
        ),
      );

      final ok = await c.uploadReceipt(
        filePath: receiptFile.path,
        total: 31.20,
      );

      expect(ok, isTrue);
      expect(c.receiptPhase.value, ReceiptUploadPhase.success);
      final posts = client.calls.where((call) => call.method == 'POST');
      expect(posts.every((call) => call.path.contains('$requestId')), isTrue);
    });

    test('18. a failed upload can be retried', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'receipt_required'}),
      );
      client
        ..stub(
          receiptPath,
          const Response(
            statusCode: 422,
            body: {'success': false, 'message': 'The receipt failed to save.'},
          ),
        )
        ..stub(
          receiptPath,
          const Response(
            statusCode: 200,
            body: {
              'success': true,
              'data': {'receipt_submitted': true},
            },
          ),
        );

      expect(
        await c.uploadReceipt(filePath: receiptFile.path, total: 12.0),
        isFalse,
      );
      expect(c.receiptPhase.value, ReceiptUploadPhase.failed);
      expect(c.receiptError.value, isNotNull);

      c.resetReceiptUpload();
      expect(c.receiptPhase.value, ReceiptUploadPhase.idle);

      expect(
        await c.uploadReceipt(filePath: receiptFile.path, total: 12.0),
        isTrue,
      );
      expect(c.receiptPhase.value, ReceiptUploadPhase.success);
    });

    test('19. a duplicate receipt is refused unless resubmit is explicit',
        () async {
      final c = await loadedController(
        cardResponse({
          'workflow_status': 'receipt_required',
          'receipt_submitted': true,
        }),
      );
      client.stub(
        receiptPath,
        const Response(
          statusCode: 200,
          body: {
            'success': true,
            'data': {'receipt_submitted': true},
          },
        ),
        times: 2,
      );

      expect(
        await c.uploadReceipt(filePath: receiptFile.path, total: 10.0),
        isFalse,
      );
      expect(c.receiptError.value, contains('already been submitted'));
      expect(client.calls.any((call) => call.path == receiptPath), isFalse);

      expect(
        await c.uploadReceipt(
          filePath: receiptFile.path,
          total: 10.0,
          allowResubmit: true,
        ),
        isTrue,
      );
    });

    test('19b. a receipt cannot be uploaded in an ineligible state', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'issuance_pending'}),
      );
      expect(
        await c.uploadReceipt(filePath: receiptFile.path, total: 10.0),
        isFalse,
      );
      expect(client.calls.any((call) => call.path == receiptPath), isFalse);
    });

    test('19c. a non-positive total is refused before the network', () async {
      final c = await loadedController(
        cardResponse({'workflow_status': 'receipt_required'}),
      );
      expect(
        await c.uploadReceipt(filePath: receiptFile.path, total: 0),
        isFalse,
      );
      expect(client.calls.any((call) => call.path == receiptPath), isFalse);
    });
  });

  // ------------------------------------------------------------------
  // 24-27. Truthfulness and safety
  // ------------------------------------------------------------------

  group('truthfulness', () {
    testWidgets('24. missing money is never rendered as a fabricated zero',
        (tester) async {
      final c = await loadedController(noCardResponse());
      await pumpScreen(tester, c);

      expect(find.textContaining(r'$0.00'), findsNothing);
      expect(find.textContaining(r'$0'), findsNothing);
      expect(find.text('Not available'), findsWidgets);
    });

    test('24b. unavailable money stays unavailable through arithmetic', () {
      const unavailable = CardMoney.unavailable();
      expect(unavailable.display, isNull);
      expect(CardMoney.parse(null).display, isNull);
      expect(CardMoney.parse('').display, isNull);
      expect(CardMoney.parse('not-a-number').display, isNull);

      // A real zero is still a real zero — the type distinguishes the two.
      expect(CardMoney.parse(0).display, r'$0.00');

      final derived = CardMoney.parse('50.00').minus(unavailable);
      expect(derived.display, isNull);
    });

    testWidgets('25. no card credentials are shown when no card exists',
        (tester) async {
      final c = await loadedController(noCardResponse());
      await pumpScreen(tester, c);

      expect(find.textContaining('••••'), findsNothing);
      expect(find.textContaining('****'), findsNothing);
      expect(find.textContaining('NEVER'), findsNothing);
      expect(find.textContaining('Card ending'), findsNothing);
      expect(find.textContaining('CARDHOLDER'), findsNothing);
    });

    testWidgets('26. there is no manual issue-card control in any state',
        (tester) async {
      for (final workflow in [
        'awaiting_provider_configuration',
        'issuance_pending',
        'issuance_failed',
        'support_required',
      ]) {
        final c = await loadedController(
          noCardResponse(workflow: workflow, provider: 'not_configured'),
        );
        await pumpScreen(tester, c);

        expect(c.state.value!.showsManualIssueControl, isFalse);
        expect(find.textContaining('Issue Card'), findsNothing,
            reason: 'issue control leaked in $workflow');
        expect(find.textContaining('Request Card'), findsNothing);
        expect(find.textContaining('Create Card'), findsNothing);
      }
    });

    test('26b. the card API surface exposes no create endpoint', () {
      final source = File('lib/services/driver_api_service.dart')
          .readAsStringSync();
      // Everything the app may call on the card is a read, a receipt, a
      // failure report or a reveal — never an issuance.
      expect(source.contains('purchase-card/issue'), isFalse);
      expect(source.contains('purchase-card/create'), isFalse);
      expect(source.contains('purchase-card/request'), isFalse);
    });

    test('26c. repeated refreshes do not multiply into repeated calls',
        () async {
      final c = await loadedController(noCardResponse());
      final before = client.calls.where((call) => call.path == cardPath).length;

      // Fire concurrently, the way an impatient double-tap would.
      await Future.wait([
        c.refreshCard(),
        c.refreshCard(),
        c.refreshCard(),
        c.refreshCard(),
      ]);

      final after = client.calls.where((call) => call.path == cardPath).length;
      expect(after - before, lessThan(4),
          reason: 'overlapping refreshes must be collapsed');
      expect(c.state.value!.lifecycle,
          CardLifecycleState.awaitingProviderConfiguration);
    });

    test('27. failure reports carry no card credentials', () async {
      final c = await loadedController(cardResponse({}));
      client.stub(
        failurePath,
        const Response(statusCode: 200, body: {'success': true}),
      );

      await c.reportFailure(
        CardFailureCategory.purchaseDeclined,
        notes: 'Terminal rejected the card',
      );

      final sent = client.calls.firstWhere(
        (call) => call.path == failurePath,
      );
      final body = sent.body as Map<String, dynamic>;

      // Only the fixed category and the driver's own words travel.
      expect(body.keys.toSet(), {'category', 'details'});
      expect(body['category'], 'declined');
      expect(body['details'], isNot(contains('4242')));
      expect(body['details'], isNot(contains('https://')));
    });

    test('27b. every failure category is one the backend accepts', () {
      const accepted = {
        'declined',
        'reveal_failed',
        'merchant_restricted',
        'expired',
        'damaged',
        'other',
      };
      for (final category in CardFailureCategory.values) {
        expect(accepted.contains(category.wireValue), isTrue,
            reason: '${category.name} would be rejected with 422');
      }
    });

    test('27c. categories that collapse onto "other" stay distinguishable',
        () {
      expect(
        CardFailureCategory.transactionMismatch.detailFor('off by 3 dollars'),
        'Transaction mismatch: off by 3 dollars',
      );
      expect(
        CardFailureCategory.cardAlreadyUsed.detailFor(null),
        'Card already used',
      );
    });
  });

  // ------------------------------------------------------------------
  // 28-30. API contract handling
  // ------------------------------------------------------------------

  group('api contract', () {
    test('28. a 401 surfaces as a session message, not a crash', () async {
      client.stub(
        cardPath,
        const Response(
          statusCode: 401,
          body: {'success': false, 'message': 'Authentication required.'},
        ),
      );
      final c = PurchaseCardController(requestId: requestId, api: api);
      await c.refreshCard();

      expect(c.state.value, isNull);
      expect(c.error.value, contains('session expired'));
    });

    test('29. a 403 says the assignment belongs to someone else', () async {
      client.stub(
        cardPath,
        const Response(
          statusCode: 403,
          body: {
            'success': false,
            'message': 'You are not the currently assigned driver.',
          },
        ),
      );
      final c = PurchaseCardController(requestId: requestId, api: api);
      await c.refreshCard();

      expect(c.state.value, isNull);
      expect(c.error.value, contains('different driver assignment'));
    });

    test('30. the provider-unconfigured envelope parses without a data block',
        () async {
      final c = await loadedController(noCardResponse());
      final s = c.state.value!;

      expect(s.hasCard, isFalse);
      expect(s.providerConfiguration,
          ProviderConfigurationStatus.notConfigured);
      expect(s.lifecycle, CardLifecycleState.awaitingProviderConfiguration);
      expect(s.approvedLimit.isAvailable, isFalse);
      expect(s.remaining.isAvailable, isFalse);
      expect(s.last4, isNull);
      expect(s.canReveal, isFalse);
      expect(s.canUploadReceipt, isFalse);
    });

    test('30b. emergency_disabled is treated as unusable', () async {
      final c = await loadedController(
        noCardResponse(
          workflow: 'issuance_pending',
          provider: 'emergency_disabled',
        ),
      );
      final s = c.state.value!;
      expect(s.providerConfiguration,
          ProviderConfigurationStatus.emergencyDisabled);
      expect(s.lifecycle, CardLifecycleState.awaitingProviderConfiguration);
      expect(s.canReveal, isFalse);
    });

    test('30c. null optional fields never crash the parser', () async {
      final c = await loadedController(
        Response(
          statusCode: 200,
          body: {
            'success': true,
            'data': {
              'card_status': null,
              'workflow_status': 'card_available',
              'provider_configuration_status': 'configured',
              'spending_limit': null,
              'remaining_balance': null,
              'currency': null,
              'last4': null,
              'expires_at': null,
              'merchant_name': null,
              'secure_reveal_available': null,
              'receipt_submitted': null,
              'receipt_total': null,
            },
          },
        ),
      );
      final s = c.state.value!;
      expect(s.lifecycle, CardLifecycleState.cardAvailable);
      expect(s.approvedLimit.display, isNull);
      expect(s.last4, isNull);
      expect(s.receiptSubmitted, isFalse);
      // No backend reveal flag means no reveal, even in a live state.
      expect(s.canReveal, isFalse);
    });

    test('30d. unknown extra fields are ignored rather than fatal', () async {
      final c = await loadedController(
        cardResponse({
          'some_future_field': {'nested': true},
          'another': [1, 2, 3],
        }),
      );
      expect(c.state.value!.lifecycle, CardLifecycleState.cardAvailable);
    });

    test('a transport failure leaves the previous state intact', () async {
      final c = await loadedController(cardResponse({}));
      expect(c.state.value!.lifecycle, CardLifecycleState.cardAvailable);

      client.throwOnNextCall = const SocketException('offline');
      await c.refreshCard();

      // A blip must not blank a card the driver is mid-purchase with.
      expect(c.state.value!.lifecycle, CardLifecycleState.cardAvailable);
      expect(c.error.value, isNotNull);
    });
  });
}
