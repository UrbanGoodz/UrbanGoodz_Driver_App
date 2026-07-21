import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urban_goodz_vendor/main.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  testWidgets('signed-out Vendor app shows the real login screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Urban Goodz Vendor'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('ENTER TESTER VENDOR MODE'), findsNothing);
  });
}
