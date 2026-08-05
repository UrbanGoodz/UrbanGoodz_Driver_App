import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppReleaseInfo {
  final bool hasUpdate;
  final bool required;
  final String? application;
  final String? platform;
  final int currentBuild;
  final String? latestVersion;
  final int? latestBuild;
  final String? minimumVersion;
  final int? minimumBuild;
  final String? apkUrl;
  final String? releaseNotes;
  final String? sha256;
  final String? signingFingerprint;

  AppReleaseInfo({
    required this.hasUpdate,
    required this.required,
    this.application,
    this.platform,
    required this.currentBuild,
    this.latestVersion,
    this.latestBuild,
    this.minimumVersion,
    this.minimumBuild,
    this.apkUrl,
    this.releaseNotes,
    this.sha256,
    this.signingFingerprint,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    return AppReleaseInfo(
      hasUpdate: json['has_update'] ?? false,
      required: json['required'] ?? false,
      application: json['application']?.toString(),
      platform: json['platform']?.toString(),
      currentBuild: (json['current_build'] as num?)?.toInt() ?? 1,
      latestVersion: json['latest_version']?.toString(),
      latestBuild: (json['latest_build'] as num?)?.toInt(),
      minimumVersion: json['minimum_version']?.toString(),
      minimumBuild: (json['minimum_build'] as num?)?.toInt(),
      apkUrl: json['apk_url']?.toString(),
      releaseNotes: json['release_notes']?.toString(),
      sha256: json['sha256']?.toString(),
      signingFingerprint: json['signing_fingerprint']?.toString(),
    );
  }
}

class AppUpdateService {
  final String baseUrl;
  final String appName; // shopper, vendor, driver
  final int currentBuildNumber;
  final String currentVersionName;

  AppUpdateService({
    required this.baseUrl,
    required this.appName,
    required this.currentBuildNumber,
    required this.currentVersionName,
  });

  Future<AppReleaseInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/app/version').replace(queryParameters: {
        'app': appName,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'build_number': currentBuildNumber.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          return AppReleaseInfo.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint('Version check offline/error: $e');
    }
    return null;
  }

  Future<bool> verifyApkIntegrity(File apkFile, String expectedSha256) async {
    if (!await apkFile.exists()) return false;
    final bytes = await apkFile.readAsBytes();
    final digest = sha256.convert(bytes);
    final calculatedSha = digest.toString().toLowerCase();
    return calculatedSha == expectedSha256.toLowerCase();
  }

  Future<void> launchInstaller(String apkUrl) async {
    final uri = Uri.parse(apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void promptOrEnforceUpdate(BuildContext context, AppReleaseInfo releaseInfo) {
    if (!releaseInfo.hasUpdate) return;

    if (releaseInfo.required) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: Colors.teal.shade900,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.system_update_force, size: 80, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        'UPDATE REQUIRED',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Version ${releaseInfo.latestVersion} is required to accept loads and dispatch orders on the Urban Goodz Driver App.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      if (releaseInfo.releaseNotes != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            releaseInfo.releaseNotes!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade900,
                          ),
                          onPressed: () {
                            if (releaseInfo.apkUrl != null) {
                              launchInstaller(releaseInfo.apkUrl!);
                            }
                          },
                          child: const Text('UPDATE NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.teal),
              const SizedBox(width: 8),
              Text('Update Available (v${releaseInfo.latestVersion})'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A newer version of the Urban Goodz Driver App is available.'),
              if (releaseInfo.releaseNotes != null) ...[
                const SizedBox(height: 12),
                const Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(releaseInfo.releaseNotes!),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (releaseInfo.apkUrl != null) {
                  launchInstaller(releaseInfo.apkUrl!);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    }
  }
}
