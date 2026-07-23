import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:urban_goodz_vendor/controllers/vendor_password_reset_controller.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';

/// Records each outgoing request and replays a queued response, so tests
/// assert the real request shape against the backend contract in
/// VendorPasswordResetController rather than a mocked repository.
class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.responses);

  final List<http.Response> responses;
  final List<http.Request> requests = [];
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    requests.add(req);
    final response = responses[_index.clamp(0, responses.length - 1)];
    _index++;
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      request: request,
    );
  }

  Map<String, dynamic> bodyAt(int i) =>
      jsonDecode(requests[i].body) as Map<String, dynamic>;
}

http.Response _json(Map<String, Object?> body, int status) =>
    http.Response(jsonEncode(body), status);

http.Response _errors(String code, String message, int status) => _json({
  'errors': [
    {'code': code, 'message': message},
  ],
}, status);

VendorPasswordResetController _controllerFor(_RecordingClient client) {
  final api = VendorApiClient(client: client);
  return VendorPasswordResetController(VendorRepository(api));
}

void main() {
  group('identifier stage', () {
    test('valid email posts the documented forgot-password body', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
      ]);
      final controller = _controllerFor(client);

      final ok = await controller.requestReset('  Store@UrbanGoodz.com  ');

      expect(ok, isTrue);
      expect(controller.stage.value, PasswordResetStage.token);
      expect(client.requests.single.method, 'POST');
      expect(
        client.requests.single.url.path,
        endsWith('/auth/vendor/forgot-password'),
      );
      // Trimmed, and sent as `email` exactly as the controller validates.
      expect(client.bodyAt(0), {'email': 'Store@UrbanGoodz.com'});
    });

    test('malformed email is rejected before any request is sent', () async {
      final client = _RecordingClient([_json({'message': 'unused'}, 200)]);
      final controller = _controllerFor(client);

      final ok = await controller.requestReset('not-an-email');

      expect(ok, isFalse);
      expect(client.requests, isEmpty);
      expect(controller.stage.value, PasswordResetStage.identifier);
      expect(controller.errorMessage.value, 'Enter a valid email address.');
    });

    test(
      'unknown email (404) advances identically to a known one, so the '
      'client does not disclose account existence',
      () async {
        final known = _RecordingClient([
          _json({'message': 'Email sent successfully.'}, 200),
        ]);
        final unknown = _RecordingClient([
          _errors('not-found', 'Email not found!', 404),
        ]);

        final knownController = _controllerFor(known);
        final unknownController = _controllerFor(unknown);

        final knownOk = await knownController.requestReset('real@vendor.test');
        final unknownOk = await unknownController.requestReset(
          'ghost@vendor.test',
        );

        expect(knownOk, isTrue);
        expect(unknownOk, isTrue);
        expect(knownController.stage.value, unknownController.stage.value);
        expect(knownController.infoMessage.value, unknownController.infoMessage.value);
        expect(knownController.errorMessage.value, isNull);
        expect(unknownController.errorMessage.value, isNull);
      },
    );

    test('mail-send failure (403) is surfaced, not swallowed', () async {
      final client = _RecordingClient([
        _errors('not-found', 'Failed to send email.', 403),
      ]);
      final controller = _controllerFor(client);

      final ok = await controller.requestReset('real@vendor.test');

      expect(ok, isFalse);
      expect(controller.stage.value, PasswordResetStage.identifier);
      expect(controller.errorMessage.value, 'Failed to send email.');
    });
  });

  group('token stage', () {
    Future<VendorPasswordResetController> atTokenStage(
      _RecordingClient client,
    ) async {
      final controller = _controllerFor(client);
      await controller.requestReset('real@vendor.test');
      return controller;
    }

    test('valid token posts email + reset_token and advances', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
        _json({'message': 'OTP found, you can proceed'}, 200),
      ]);
      final controller = await atTokenStage(client);

      final ok = await controller.verifyToken('654321');

      expect(ok, isTrue);
      expect(controller.stage.value, PasswordResetStage.newPassword);
      expect(client.requests[1].url.path, endsWith('/auth/vendor/verify-token'));
      expect(client.bodyAt(1), {
        'email': 'real@vendor.test',
        'reset_token': '654321',
      });
    });

    test('invalid token (400) keeps the user on the token stage', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
        _errors('reset_token', 'Invalid OTP.', 400),
      ]);
      final controller = await atTokenStage(client);

      final ok = await controller.verifyToken('000000');

      expect(ok, isFalse);
      expect(controller.stage.value, PasswordResetStage.token);
      expect(controller.errorMessage.value, 'Invalid OTP.');
    });

    test('temp block (405) surfaces the server wait message verbatim', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
        _errors('otp_temp_blocked', 'Too many attemps', 405),
      ]);
      final controller = await atTokenStage(client);

      await controller.verifyToken('111111');

      expect(controller.errorMessage.value, 'Too many attemps');
      expect(controller.stage.value, PasswordResetStage.token);
    });

    test('empty token is rejected without a request', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
      ]);
      final controller = await atTokenStage(client);

      final ok = await controller.verifyToken('   ');

      expect(ok, isFalse);
      expect(client.requests, hasLength(1)); // only the forgot-password call
    });

    test('resend is blocked while the cooldown is running', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
      ]);
      final controller = await atTokenStage(client);

      expect(controller.resendSeconds.value, greaterThan(0));
      final ok = await controller.resendCode();

      expect(ok, isFalse);
      expect(client.requests, hasLength(1));
      controller.onClose();
    });
  });

  group('new password stage', () {
    Future<VendorPasswordResetController> atPasswordStage(
      _RecordingClient client,
    ) async {
      final controller = _controllerFor(client);
      await controller.requestReset('real@vendor.test');
      await controller.verifyToken('654321');
      return controller;
    }

    List<http.Response> preamble() => [
      _json({'message': 'Email sent successfully.'}, 200),
      _json({'message': 'OTP found, you can proceed'}, 200),
    ];

    test('successful reset PUTs the documented body', () async {
      final client = _RecordingClient([
        ...preamble(),
        _json({'message': 'Password changed successfully.'}, 200),
      ]);
      final controller = await atPasswordStage(client);

      final ok = await controller.submitNewPassword('Str0ng!Pass', 'Str0ng!Pass');

      expect(ok, isTrue);
      expect(controller.stage.value, PasswordResetStage.success);
      expect(client.requests[2].method, 'PUT');
      expect(
        client.requests[2].url.path,
        endsWith('/auth/vendor/reset-password'),
      );
      expect(client.bodyAt(2), {
        'email': 'real@vendor.test',
        'reset_token': '654321',
        'password': 'Str0ng!Pass',
        'confirm_password': 'Str0ng!Pass',
      });
    });

    test('mismatch is caught locally, before any request', () async {
      final client = _RecordingClient(preamble());
      final controller = await atPasswordStage(client);

      final ok = await controller.submitNewPassword('Str0ng!Pass', 'Other!Pass1');

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Passwords do not match.');
      expect(client.requests, hasLength(2));
    });

    test('local rules mirror the backend Password rule set', () {
      expect(VendorPasswordResetController.validatePassword('Sh0rt!'), isNotNull);
      expect(
        VendorPasswordResetController.validatePassword('alllower1!'),
        contains('uppercase'),
      );
      expect(
        VendorPasswordResetController.validatePassword('NoNumbers!'),
        contains('number'),
      );
      expect(
        VendorPasswordResetController.validatePassword('NoSymbols1'),
        contains('symbol'),
      );
      expect(VendorPasswordResetController.validatePassword('Str0ng!Pass'), isNull);
    });

    test(
      'server-side password rejection (403) is rendered verbatim, including '
      'the uncompromised check the client cannot perform',
      () async {
        final client = _RecordingClient([
          ...preamble(),
          _errors(
            'password',
            'The password is compromised. Please choose a different one',
            403,
          ),
        ]);
        final controller = await atPasswordStage(client);

        final ok = await controller.submitNewPassword(
          'Passw0rd!',
          'Passw0rd!',
        );

        expect(ok, isFalse);
        expect(
          controller.errorMessage.value,
          'The password is compromised. Please choose a different one',
        );
        expect(controller.stage.value, PasswordResetStage.newPassword);
      },
    );

    test('consumed/invalid code (400) sends the user back to the token stage',
        () async {
      final client = _RecordingClient([
        ...preamble(),
        _errors('invalid', 'Invalid OTP.', 400),
      ]);
      final controller = await atPasswordStage(client);

      final ok = await controller.submitNewPassword('Str0ng!Pass', 'Str0ng!Pass');

      expect(ok, isFalse);
      expect(controller.stage.value, PasswordResetStage.token);
      expect(controller.errorMessage.value, contains('no longer valid'));
    });
  });

  group('navigation and cleanup', () {
    test('back from token returns to identifier without popping', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
      ]);
      final controller = _controllerFor(client);
      await controller.requestReset('real@vendor.test');

      expect(controller.goBack(), isFalse);
      expect(controller.stage.value, PasswordResetStage.identifier);
      controller.onClose();
    });

    test('back from identifier signals pop and clears state', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
      ]);
      final controller = _controllerFor(client);
      await controller.requestReset('real@vendor.test');
      controller.goBack(); // token -> identifier

      expect(controller.goBack(), isTrue);
      expect(controller.email.value, isEmpty);
      expect(controller.resendSeconds.value, 0);
    });

    test('reset() clears the email and cooldown', () async {
      final client = _RecordingClient([
        _json({'message': 'Email sent successfully.'}, 200),
      ]);
      final controller = _controllerFor(client);
      await controller.requestReset('real@vendor.test');

      controller.reset();

      expect(controller.email.value, isEmpty);
      expect(controller.stage.value, PasswordResetStage.identifier);
      expect(controller.errorMessage.value, isNull);
      expect(controller.resendSeconds.value, 0);
    });
  });
}
