import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteConfigService {
  final String baseUrl;
  final String appName;
  Map<String, dynamic> _marketplaceModules = {};
  Map<String, dynamic> _rawConfigs = {};

  RemoteConfigService({
    required this.baseUrl,
    required this.appName,
  });

  Map<String, dynamic> get modules => _marketplaceModules;

  Future<void> fetchRemoteConfig() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/app/config').replace(queryParameters: {
        'app': appName,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          _marketplaceModules = body['marketplace_modules'] as Map<String, dynamic>? ?? {};
          _rawConfigs = body['configs'] as Map<String, dynamic>? ?? {};
        }
      }
    } catch (e) {
      debugPrint('Remote config fetch offline/error: $e');
    }
  }

  dynamic getValue(String key, {dynamic defaultValue}) {
    return _rawConfigs[key] ?? defaultValue;
  }
}
