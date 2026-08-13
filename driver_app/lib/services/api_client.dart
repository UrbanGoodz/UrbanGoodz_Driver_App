import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';

/// Thin wrapper around GetConnect that injects the driver token as a `?token=`
/// query parameter on every request. The backend `dm.api` middleware validates
/// `?token=` against delivery_men.auth_token — it does NOT read Bearer headers.
class ApiClient extends GetConnect {
  ApiClient() {
    baseUrl = ApiConfig.baseUrl;
    timeout = const Duration(seconds: 30);
    httpClient.addRequestModifier<void>((request) {
      request.headers['Accept'] = 'application/json';
      return request;
    });
  }

  /// Invoked when an authenticated request is rejected with HTTP 401, i.e. the
  /// stored token was revoked, rotated or expired server-side. Wired once in
  /// `main()` so session teardown happens in a single place instead of every
  /// screen silently swallowing the failure and showing an empty dashboard.
  static void Function()? onUnauthorized;

  String get _token {
    try {
      return Get.find<DriverAuthController>().token.value;
    } catch (_) {
      return '';
    }
  }

  Map<String, String> get _authQuery {
    final t = _token;
    return t.isNotEmpty ? {'token': t} : {};
  }

  /// Fires the session-expiry hook, but only for requests that actually
  /// carried a token — an unauthenticated probe returning 401 is expected and
  /// must not log anybody out.
  Response _checkAuth(Response res, bool hadToken) {
    if (hadToken && res.statusCode == 401) {
      onUnauthorized?.call();
    }
    return res;
  }

  Future<Response> authGet(String path, {Map<String, dynamic>? query}) async {
    final hadToken = _token.isNotEmpty;
    final merged = <String, dynamic>{..._authQuery, ...?query};
    return _checkAuth(await get(path, query: merged), hadToken);
  }

  Future<Response> authPost(
    String path,
    dynamic body, {
    Map<String, dynamic>? query,
  }) async {
    final hadToken = _token.isNotEmpty;
    final merged = <String, dynamic>{..._authQuery, ...?query};
    return _checkAuth(await post(path, body, query: merged), hadToken);
  }

  Future<Response> authPut(
    String path,
    dynamic body, {
    Map<String, dynamic>? query,
  }) async {
    final hadToken = _token.isNotEmpty;
    final merged = <String, dynamic>{..._authQuery, ...?query};
    return _checkAuth(await put(path, body, query: merged), hadToken);
  }

  Future<Response> authDelete(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final hadToken = _token.isNotEmpty;
    final merged = <String, dynamic>{..._authQuery, ...?query};
    return _checkAuth(await delete(path, query: merged), hadToken);
  }
}

/// A single entry from the backend's `errors` array.
class ApiFieldError {
  final String code;
  final String message;

  const ApiFieldError(this.code, this.message);

  factory ApiFieldError.fromJson(dynamic json) {
    if (json is Map) {
      return ApiFieldError(
        json['code']?.toString() ?? '',
        json['message']?.toString() ?? '',
      );
    }
    return ApiFieldError('', json?.toString() ?? '');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final List<ApiFieldError> errors;

  /// First error code returned by the backend, e.g. `auth-001` for bad
  /// credentials or a field name such as `phone` for validation failures.
  /// Empty when the response carried no `errors` array.
  final String code;

  /// Seconds the caller must wait before retrying, from the `retry-after`
  /// header on HTTP 429 responses.
  final int? retryAfterSeconds;

  ApiException(
    this.statusCode,
    this.message, {
    this.errors = const [],
    this.code = '',
    this.retryAfterSeconds,
  });

  /// True when the backend rejected or expired the session token.
  bool get isUnauthorized => statusCode == 401;

  /// True when the login throttle (5 attempts) has been tripped.
  bool get isRateLimited => statusCode == 429;

  /// Builds an exception from the live Urban Goodz error envelopes, verified
  /// against admin.urbangoodzdelivery.com on 2026-07-23:
  ///
  ///   403 validation  {"errors":[{"code":"phone","message":"The phone field
  ///                    is required."}, ...]}
  ///   401 bad creds   {"errors":[{"code":"auth-001","message":"Incorrect
  ///                    credential  please try again"}]}
  ///   429 throttled   {"message":"Too Many Attempts."} + `retry-after` header
  ///
  /// The previous implementation only read a top-level `message` key, so every
  /// `errors`-array response (which is what login actually returns) collapsed
  /// to the useless string "Request failed (HTTP 401)".
  factory ApiException.fromResponse(Response res) {
    final status = res.statusCode ?? 0;
    final body = res.body;

    var retryAfter = int.tryParse(
      res.headers?['retry-after'] ?? res.headers?['Retry-After'] ?? '',
    );

    final parsed = <ApiFieldError>[];
    String? message;

    if (body is Map) {
      final raw = body['errors'];
      if (raw is List) {
        parsed.addAll(raw.map(ApiFieldError.fromJson));
      } else if (raw is Map) {
        // Some legacy routes return {"errors": {"field": ["msg"]}}.
        raw.forEach((key, value) {
          final text = value is List ? value.join(' ') : value.toString();
          parsed.add(ApiFieldError(key.toString(), text));
        });
      }
      if (body['message'] != null) message = body['message'].toString();
    }

    final joined = parsed
        .map((e) => e.message)
        .where((m) => m.isNotEmpty)
        .join('\n');

    final resolved = joined.isNotEmpty
        ? joined
        : (message != null && message.isNotEmpty
              ? message
              : 'Request failed (HTTP $status).');

    if (status == 429) retryAfter ??= 60;

    return ApiException(
      status,
      resolved,
      errors: parsed,
      code: parsed.isNotEmpty ? parsed.first.code : '',
      retryAfterSeconds: retryAfter,
    );
  }

  @override
  String toString() =>
      'ApiException($statusCode${code.isEmpty ? '' : '/$code'}): $message';
}
