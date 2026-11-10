import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/utils/recipient_dialog.dart';

void main() {
  testWidgets('returns trimmed name on Complete delivery', (t) async {
    await t.pumpWidget(const GetMaterialApp(home: Scaffold()));
    String? result = 'unset';
    final f = askDeliveryRecipient().then((v) => result = v);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '  Sam Lee ');
    await t.tap(find.text('Complete delivery'));
    await t.pumpAndSettle();
    await f;
    expect(result, 'Sam Lee');
  });

  testWidgets('empty submit returns empty string, cancel returns null',
      (t) async {
    await t.pumpWidget(const GetMaterialApp(home: Scaffold()));
    String? result = 'unset';
    var f = askDeliveryRecipient().then((v) => result = v);
    await t.pumpAndSettle();
    await t.tap(find.text('Complete delivery'));
    await t.pumpAndSettle();
    await f;
    expect(result, '');

    f = askDeliveryRecipient().then((v) => result = v);
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    await f;
    expect(result, isNull);
  });

  test('ApiException reads a top-level code', () {
    final e = ApiException.fromResponse(const Response(
      statusCode: 422,
      body: {'message': 'x', 'code': 'recipient_required'},
    ));
    expect(e.code, 'recipient_required');
  });
}
