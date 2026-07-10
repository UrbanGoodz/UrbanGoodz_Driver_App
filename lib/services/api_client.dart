import 'package:get/get.dart';
import 'package:urban_goodz_driver/config/api_config.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';

/// Thin wrapper around GetConnect that injects the driver bearer token and
/// normalizes API errors. All driver endpoints are guarded by auth:delivery_man.
class ApiClient extends GetConnect {
  ApiClient() {
    baseUrl = ApiConfig.baseUrl;
    timeout = const Duration(seconds: 30);
    httpClient.addRequestModifier<void>((request) {
      request.headers['Accept'] = 'application/json';
      final auth = Get.find<DriverAuthController>();
      final token = auth.token.value;
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.statusCode, this.message, [this.errors]);

  @override
  String toString() =>
      'ApiException($statusCode): $message${errors != null ? ' $errors' : ''}';
}
