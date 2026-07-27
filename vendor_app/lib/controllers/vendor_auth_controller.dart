import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';
import 'dart:async';

class VendorAuthController extends GetxController {
  VendorAuthController(this.repository, this.api);

  static const _tokenKey = 'vendor_api_token';
  static const _emailKey = 'vendor_email';

  final VendorRepository repository;
  final VendorApiClient api;

  final isLoggedIn = false.obs;
  final isInitialized = false.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  /// One of: unknown | approved | pending | suspended | store_missing |
  /// denied | subscription_required. Every value maps to a state the backend
  /// actually emits; none is invented.
  final approvalStatus = 'unknown'.obs;

  /// True when the backend answered 200 with a `subscribed` payload instead
  /// of a usable session (store_business_model == 'none').
  final requiresSubscription = false.obs;

  final businessName = ''.obs;
  final ownerName = ''.obs;
  final phone = ''.obs;
  final email = ''.obs;
  final city = ''.obs;
  final businessType = ''.obs;
  final addressNotes = ''.obs;
  final storeStatus = 'closed'.obs;
  final sizingQuoteRequests = <FashionFitQuoteRequest>[].obs;
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  void onInit() {
    super.onInit();
    api.onUnauthorized = () async {
      await _clearSession();
      isLoggedIn.value = false;
      errorMessage.value = 'Your session expired. Please sign in again.';
    };
    if (Firebase.apps.isNotEmpty) {
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((token) async {
            if (isLoggedIn.value && token.isNotEmpty) {
              await repository.updateFcmToken(token);
            }
          });
    }
    _restoreSession();
  }

  @override
  void onClose() {
    _tokenRefreshSubscription?.cancel();
    super.onClose();
  }

  Future<void> _restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(_tokenKey);
      email.value = preferences.getString(_emailKey) ?? '';
      if (token != null && token.isNotEmpty) {
        api.setToken(token);
        try {
          await refreshProfile().timeout(const Duration(seconds: 15));
          isLoggedIn.value = true;
          await _registerFcmToken();
        } on VendorApiException catch (error) {
          if (error.statusCode == 401 || error.statusCode == 403) {
            await _clearSession();
          } else {
            errorMessage.value = error.message;
          }
        } catch (_) {
          await _clearSession();
        }
      }
    } catch (_) {
    } finally {
      isInitialized.value = true;
    }
  }

  /// Extracts the machine-readable error code the backend emits, e.g.
  /// `auth-001`, `auth-002`, `store_inactive`, `store_missing`.
  ///
  /// Preferred over matching on `message`, which is passed through
  /// `translate()` server-side and therefore changes with the vendor's
  /// language.
  static String? _errorCode(VendorApiException error) {
    final body = error.body;
    if (body is! Map) return null;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty && errors.first is Map) {
      return (errors.first as Map)['code']?.toString();
    }
    return null;
  }

  /// Maps a login failure to an account state.
  ///
  /// Only states the backend actually emits are used. `VendorLoginController`
  /// + `storeSubscriptionCheck` produce exactly:
  ///   auth-001       401  credentials rejected (or rental addon unavailable)
  ///   auth-002       403  registration not approved yet
  ///   store_inactive 403  store or owner not active -> suspended
  ///   store_missing  403  no store assigned to the vendor
  /// There is no "rejected" state in the backend, so none is invented here.
  static String _accountStateFor(VendorApiException error) {
    switch (_errorCode(error)) {
      case 'auth-002':
        return 'pending';
      case 'store_inactive':
        return 'suspended';
      case 'store_missing':
        return 'store_missing';
      case 'auth-001':
        return 'denied';
      default:
        return error.statusCode == 403 ? 'denied' : 'unknown';
    }
  }

  Future<bool> login(String emailAddress, String password) async {
    isLoading.value = true;
    errorMessage.value = null;
    requiresSubscription.value = false;
    approvalStatus.value = 'unknown';
    try {
      final result = await repository.login(emailAddress.trim(), password);

      // A store on `store_business_model == 'none'` gets HTTP 200 carrying a
      // `subscribed` payload rather than a normal session. It contains a
      // token, so it must be rejected explicitly or the vendor would land on
      // a dashboard they have no active subscription for.
      if (result['requires_subscription'] == true) {
        requiresSubscription.value = true;
        approvalStatus.value = 'subscription_required';
        errorMessage.value =
            'This store needs an active subscription before you can sign in.';
        return false;
      }

      final token = result['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const VendorApiException(
          500,
          'Login succeeded without a Vendor token.',
        );
      }
      api.setToken(token);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);
      await preferences.setString(_emailKey, emailAddress.trim());
      email.value = emailAddress.trim();
      // Identity comes from GET vendor/profile; the login response carries
      // only token, zone_wise_topic and module_type.
      await refreshProfile();
      approvalStatus.value = 'approved';
      isLoggedIn.value = true;
      await _registerFcmToken();
      return true;
    } on VendorApiException catch (error) {
      approvalStatus.value = _accountStateFor(error);
      errorMessage.value = error.message;
      await _clearSession();
      return false;
    } catch (error) {
      errorMessage.value = 'Unable to reach the Vendor API: $error';
      await _clearSession();
      return false;
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> refreshProfile() async {
    final profile = await repository.profile();
    final storeValue = profile['stores'];
    final store = storeValue is Map
        ? Map<String, dynamic>.from(storeValue)
        : <String, dynamic>{};
    businessName.value = store['name']?.toString() ?? '';
    ownerName.value = [
      profile['f_name'],
      profile['l_name'],
    ].where((value) => value != null && value.toString().isNotEmpty).join(' ');
    phone.value =
        profile['phone']?.toString() ?? store['phone']?.toString() ?? '';
    email.value =
        profile['email']?.toString() ??
        store['email']?.toString() ??
        email.value;
    city.value = store['address']?.toString() ?? '';
    addressNotes.value = store['address']?.toString() ?? '';
    final module = store['module'];
    businessType.value = module is Map
        ? module['module_name']?.toString() ??
              module['module_type']?.toString() ??
              ''
        : '';
    storeStatus.value = _bool(store['active']) ? 'open' : 'closed';
    approvalStatus.value = _bool(store['status']) ? 'approved' : 'pending';
    await refreshFashionMeasurements();
  }

  Future<void> refreshFashionMeasurements() async {
    try {
      final rows = await repository.fashionRequests();
      final details = <FashionFitQuoteRequest>[];
      for (final row in rows) {
        final uuid = row['uuid']?.toString();
        if (uuid == null || uuid.isEmpty) continue;
        final detail = await repository.fashionRequest(uuid);
        details.add(
          FashionFitQuoteRequest.fromJson(
            detail['data'] is Map
                ? Map<String, dynamic>.from(detail['data'])
                : detail,
          ),
        );
      }
      sizingQuoteRequests.assignAll(details);
    } on VendorApiException catch (error) {
      errorMessage.value = error.message;
      sizingQuoteRequests.clear();
    }
  }

  Future<bool> submitFashionReview(
    FashionFitQuoteRequest request,
    double fee,
    String? notes,
  ) async {
    try {
      final days = RegExp(r'\d+').firstMatch(notes ?? '')?.group(0);
      await repository.submitFashionEstimate(
        request.id,
        amountMinor: (fee * 100).round(),
        timelineDays: int.tryParse(days ?? '') ?? 3,
        notes: notes ?? 'Provider estimate',
      );
      await refreshFashionMeasurements();
      return true;
    } on VendorApiException catch (error) {
      errorMessage.value = error.message;
      return false;
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await repository.updateFcmToken(token);
      }
    } catch (_) {
      // Push registration is non-fatal; login and API access remain available.
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } finally {
      await _clearSession();
      isLoggedIn.value = false;
    }
  }

  Future<void> _clearSession() async {
    api.setToken(null);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    businessName.value = '';
    ownerName.value = '';
    sizingQuoteRequests.clear();
  }

  static bool _bool(Object? value) =>
      value == true || value == 1 || value?.toString() == '1';
}

class FashionFitQuoteRequest {
  final String id;
  final String customerName;
  final String customerPhone;
  final String chestSize;
  final String waistSize;
  final String inseam;
  final String gender;
  final String requestType;
  final String date;
  final String status;
  final double? quoteAmount;
  final String? notes;
  final String? estCompletion;

  const FashionFitQuoteRequest({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.chestSize,
    required this.waistSize,
    required this.inseam,
    required this.gender,
    required this.requestType,
    required this.status,
    required this.date,
    this.quoteAmount,
    this.notes,
    this.estCompletion,
  });

  factory FashionFitQuoteRequest.fromJson(Map<String, dynamic> json) {
    final request = json['request'] is Map
        ? Map<String, dynamic>.from(json['request'])
        : json;
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'])
        : <String, dynamic>{};
    final measurements = profile['measurements'] is List
        ? profile['measurements'] as List
        : const [];
    String measurement(String key) {
      Map? match;
      for (final row in measurements.whereType<Map>()) {
        if (row['name']?.toString() == key) {
          match = row;
          break;
        }
      }
      return match == null
          ? 'Not provided'
          : '${match['value']} ${match['unit'] ?? ''} (${match['source'] ?? 'AI'})';
    }

    return FashionFitQuoteRequest(
      id: request['uuid']?.toString() ?? '',
      customerName: 'Customer #${request['customer_id'] ?? 'Private'}',
      customerPhone: 'Private',
      chestSize: measurement('chest_bust'),
      waistSize: measurement('waist'),
      inseam: measurement('inseam'),
      gender: profile['fit_preferences']?.toString() ?? 'Not provided',
      requestType:
          request['service_type']?.toString() ??
          request['garment_type']?.toString() ??
          'Fashion measurement review',
      status: request['status']?.toString() ?? 'submitted',
      date: request['created_at']?.toString() ?? '',
      quoteAmount: null,
      notes: null,
      estCompletion: request['requested_completion_date']?.toString(),
    );
  }
}
