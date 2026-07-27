import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/main.dart';

import 'helpers/test_bootstrap.dart';

void main() {
  late Map<String, Map<String, String>> languages;

  setUp(() async {
    Get.testMode = true;
    languages = await initTestDependencies();
  });

  tearDown(resetGetx);

  testWidgets('Urban Goodz app renders GetMaterialApp on startup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(languages: languages, body: null));
    await tester.pump();

    expect(find.byType(GetMaterialApp), findsOneWidget);

    // The splash screen arms two real timers before it can settle:
    //
    //   1. a 5s timeout on getConfigData, which under test never resolves
    //      because there is no network, and
    //   2. a 1s timer that then routes onward via the no-config fallback.
    //
    // Both must be drained or the test ends with pending timers. Advancing
    // only 1s (as this test previously did) leaves the 5s timeout armed,
    // which is what made it fail rather than anything in app startup.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 2));

    // Startup survived the config fetch failing: still one app, no crash.
    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
