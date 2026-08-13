import 'dart:async';

import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

/// Records every authenticated call and replays canned responses, so tests
/// exercise the real controller/service code without Flutter's widget-test
/// HttpClient (which refuses live requests).
class FakeApiClient extends ApiClient {
  FakeApiClient();

  /// path -> response factory. Queued responses are consumed in order, so a
  /// test can make the first call fail and the second succeed.
  final Map<String, List<Response>> queued = {};

  final List<({String method, String path, dynamic body})> calls = [];

  /// Thrown instead of returning, to simulate a socket failure.
  Object? throwOnNextCall;

  void stub(String path, Response response, {int times = 1}) {
    queued.putIfAbsent(path, () => []).addAll(List.filled(times, response));
  }

  Response _take(String method, String path, dynamic body) {
    calls.add((method: method, path: path, body: body));

    final err = throwOnNextCall;
    if (err != null) {
      throwOnNextCall = null;
      throw err;
    }

    final list = queued[path];
    if (list == null || list.isEmpty) {
      return const Response(statusCode: 404, body: {'message': 'no stub'});
    }
    return list.length == 1 ? list.first : list.removeAt(0);
  }

  @override
  Future<Response> authGet(String path, {Map<String, dynamic>? query}) async =>
      _take('GET', path, null);

  @override
  Future<Response> authPost(
    String path,
    dynamic body, {
    Map<String, dynamic>? query,
  }) async => _take('POST', path, body);

  @override
  Future<Response> authPut(
    String path,
    dynamic body, {
    Map<String, dynamic>? query,
  }) async => _take('PUT', path, body);

  @override
  Future<Response> authDelete(
    String path, {
    Map<String, dynamic>? query,
  }) async => _take('DELETE', path, null);
}

/// Drives [DriverApiService] outcomes without touching HTTP.
class FakeDriverApiService extends DriverApiService {
  FakeDriverApiService({super.client});

  Map<String, dynamic> profile = const {};
  Object? profileError;
  int profileCalls = 0;

  Map<String, dynamic> loginResult = const {};
  Object? loginError;

  List<BusinessJobModel> businessJobs = const [];
  Object? businessJobsError;

  @override
  Future<List<BusinessJobModel>> getBusinessJobs() async {
    final err = businessJobsError;
    if (err != null) throw err;
    return businessJobs;
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    profileCalls++;
    final err = profileError;
    if (err != null) throw err;
    return profile;
  }

  @override
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final err = loginError;
    if (err != null) throw err;
    return loginResult;
  }
}
