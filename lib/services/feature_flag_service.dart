import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FeatureFlagService {
  final String baseUrl;
  final String appName;
  final Map<String, bool> _flags = {};

  FeatureFlagService({
    required this.baseUrl,
    required this.appName,
  });

  Future<void> fetchFeatureFlags() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/app/feature-flags').replace(queryParameters: {
        'app': appName,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success' && body['flags'] != null) {
          final map = body['flags'] as Map<String, dynamic>;
          map.forEach((k, v) {
            _flags[k] = v == true;
          });
        }
      }
    } catch (e) {
      debugPrint('Feature flags fetch offline/error: $e');
    }
  }

  bool isEnabled(String featureKey, {bool defaultValue = true}) {
    return _flags[featureKey] ?? defaultValue;
  }
}
