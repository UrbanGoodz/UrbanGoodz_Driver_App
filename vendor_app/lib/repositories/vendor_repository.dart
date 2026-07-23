import 'dart:convert';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';

class VendorRepository {
  VendorRepository(this.api);

  final VendorApiClient api;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = _map(
      await api.post(
        'auth/vendor/login',
        body: {'email': email, 'password': password, 'vendor_type': 'owner'},
      ),
    );
    final subscription = body['subscribed'];
    return subscription is Map<String, dynamic>
        ? subscription
        : subscription is Map
        ? Map<String, dynamic>.from(subscription)
        : body;
  }

  Future<Map<String, dynamic>> profile() async =>
      _map(await api.get('vendor/profile'));

  Future<void> logout() async => api.post('vendor/logout');

  // ---------------------------------------------------------------------
  // Password recovery.
  //
  // Contract read directly from the backend implementation at
  // app/Http/Controllers/Api/V1/Auth/VendorPasswordResetController.php.
  // Shapes are NOT inferred from the Admin panel web flow.
  //
  //   POST auth/vendor/forgot-password  {email}
  //        200 {message}                       -> 6-digit code issued + mailed
  //        404 {errors:[{code:'not-found'}]}   -> email unknown (see note)
  //        403 {errors:[...]}                  -> validation, or mail send failed
  //
  //   POST auth/vendor/verify-token     {email, reset_token}
  //        200 {message}                       -> code accepted
  //        400 {errors:[{code:'reset_token'}]} -> invalid code
  //        405 {errors:[{code:'otp_block_time'|'otp_temp_blocked'}]}
  //        403 {errors:[...]}                  -> validation
  //
  //   PUT  auth/vendor/reset-password   {email, reset_token, password,
  //                                      confirm_password}
  //        200 {message}                       -> password changed
  //        400 {errors:[{code:'invalid'}]}     -> bad or already-consumed code
  //        401 {errors:[{code:'mismatch'}]}    -> confirmation mismatch
  //        403 {errors:[...]}                  -> password rule violations
  //
  // Enumeration note: the backend discloses account existence via the 404 on
  // forgot-password and via `exists:vendors,email` validation on the other
  // two endpoints. That is backend-side and cannot be fixed from this app.
  // VendorPasswordResetController (mobile) presents a single generic outcome
  // so the client does not amplify the disclosure.

  Future<void> requestPasswordReset(String email) async =>
      api.post('auth/vendor/forgot-password', body: {'email': email});

  Future<void> verifyPasswordResetToken({
    required String email,
    required String resetToken,
  }) async => api.post(
    'auth/vendor/verify-token',
    body: {'email': email, 'reset_token': resetToken},
  );

  Future<void> submitPasswordReset({
    required String email,
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async => api.put(
    'auth/vendor/reset-password',
    body: {
      'email': email,
      'reset_token': resetToken,
      'password': password,
      'confirm_password': confirmPassword,
    },
  );

  Future<List<Map<String, dynamic>>> currentOrders() async =>
      _list(await api.get('vendor/current-orders'));

  Future<List<Map<String, dynamic>>> allOrders() async =>
      _list(await api.get('vendor/all-orders'));

  Future<Map<String, dynamic>> completedOrders({
    int limit = 50,
    int offset = 1,
    String status = 'all',
  }) async => _map(
    await api.get(
      'vendor/completed-orders',
      query: {'limit': limit, 'offset': offset, 'status': status},
    ),
  );

  Future<Map<String, dynamic>> canceledOrders({
    int limit = 50,
    int offset = 1,
  }) async => _map(
    await api.get(
      'vendor/canceled-orders',
      query: {'limit': limit, 'offset': offset},
    ),
  );

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? reason,
    int? processingTime,
  }) async {
    final body = <String, Object?>{'order_id': orderId, 'status': status};
    if (reason != null) body['reason'] = reason;
    if (processingTime != null) body['processing_time'] = processingTime;
    await api.put('vendor/update-order-status', body: body);
  }

  Future<Map<String, dynamic>> items({
    int limit = 100,
    int offset = 1,
    String? search,
  }) async => _map(
    await api.get(
      'vendor/get-items-list',
      query: {
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    ),
  );

  Future<void> updateStock(String productId, int stock) async {
    await api.put(
      'vendor/item/stock-update',
      body: {'product_id': productId, 'current_stock': stock},
    );
  }

  Future<void> saveProduct({
    String? id,
    required String name,
    required String description,
    required String categoryId,
    required double price,
    required int stock,
    String? imagePath,
  }) async {
    final fields = <String, String>{
      'category_id': categoryId,
      'price': price.toStringAsFixed(2),
      'discount': '0',
      'discount_type': 'percent',
      'stock': stock.toString(),
      'translations': jsonEncode([
        {'locale': 'en', 'key': 'name', 'value': name},
        {'locale': 'en', 'key': 'description', 'value': description},
      ]),
    };
    if (id != null) {
      fields['_method'] = 'PUT';
      fields['item_id'] = id;
    }
    final files = <String, String>{};
    if (imagePath != null) {
      files['image'] = imagePath;
    }
    await api.multipart(
      id == null ? 'vendor/item/store' : 'vendor/item/update',
      method: 'POST',
      fields: fields,
      files: files,
    );
  }

  Future<void> toggleStoreStatus() async =>
      api.post('vendor/update-active-status');

  Future<void> updateFcmToken(String token) async =>
      api.put('vendor/update-fcm-token', body: {'fcm_token': token});

  Future<List<Map<String, dynamic>>> notifications() async =>
      _list(await api.get('vendor/notifications'));

  Future<Map<String, dynamic>> earnings() async =>
      _map(await api.get('vendor/earning-info'));

  Future<List<Map<String, dynamic>>> withdrawals() async =>
      _list(await api.get('vendor/get-withdraw-list'));

  Future<List<Map<String, dynamic>>> withdrawalMethods() async {
    final response = await api.get('vendor/get-withdraw-method-list');
    if (response is List) return _list(response);
    final map = _map(response);
    return _list(map['withdrawal_methods'] ?? map['methods'] ?? map['data']);
  }

  Future<void> requestWithdrawal(double amount, String methodId) async {
    await api.post(
      'vendor/request-withdraw',
      body: {'amount': amount, 'id': methodId},
    );
  }

  Future<List<Map<String, dynamic>>> fashionMeasurements() async {
    final response = _map(
      await api.get('vendor/urban-goodz/fashion/measurements'),
    );
    final data = response['data'];
    if (data is Map) return _list(data['data']);
    return _list(data);
  }

  Future<void> reviewFashionMeasurement(
    String id, {
    required double fee,
    String? notes,
  }) async {
    await api.post(
      'vendor/urban-goodz/fashion/measurements/$id/review',
      body: {
        'vendor_review_fee': fee,
        'tailor_notes': notes,
        'review_status': 'ready_to_quote',
        'measurement_status': 'tailor_adjusted',
      },
    );
  }

  Future<Map<String, dynamic>> fashionProviderProfile() async =>
      _map(await api.get('vendor/fashion-fit/profile'));

  Future<void> updateFashionProviderProfile(Map<String, Object?> data) async =>
      api.put('vendor/fashion-fit/profile', body: data);

  Future<List<Map<String, dynamic>>> fashionRequests({String? status}) async =>
      _pagedList(
        await api.get(
          'vendor/fashion-fit/requests',
          query: {'status': status ?? ''},
        ),
      );

  Future<Map<String, dynamic>> fashionRequest(String uuid) async =>
      _map(await api.get('vendor/fashion-fit/requests/$uuid'));

  Future<void> submitFashionEstimate(
    String uuid, {
    required int amountMinor,
    required int timelineDays,
    required String notes,
  }) async => api.post(
    'vendor/fashion-fit/requests/$uuid/estimates',
    body: {
      'amount': amountMinor / 100,
      'currency': 'USD',
      'timeline_days': timelineDays,
      'notes': notes,
    },
  );

  Future<void> updateFashionStatus(String uuid, String status) async =>
      api.post(
        'vendor/fashion-fit/requests/$uuid/status',
        body: {'status': status},
      );

  Future<List<Map<String, dynamic>>> serviceBookings({String? status}) async =>
      _pagedList(
        await api.get(
          'vendor/service-bookings/bookings',
          query: {if (status != null && status != 'all') 'status': status},
        ),
      );

  Future<void> quoteServiceBooking(
    String id, {
    required int amountMinor,
    int depositMinor = 0,
    required DateTime scheduledAt,
    String? notes,
  }) async => api.post(
    'vendor/service-bookings/bookings/$id/quote',
    body: {
      'amount_minor': amountMinor,
      'deposit_minor': depositMinor,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'notes': notes,
    },
  );

  Future<void> updateServiceBookingStatus(
    String id,
    String status, {
    String? notes,
  }) async => api.post(
    'vendor/service-bookings/bookings/$id/status',
    body: {'status': status, 'notes': notes},
  );

  Future<Map<String, dynamic>> serviceProviderProfile() async =>
      _map(await api.get('vendor/service-bookings/profile'));
  Future<void> updateServiceProviderProfile(Map<String, Object?> data) async =>
      api.put('vendor/service-bookings/profile', body: data);
  Future<void> updateProviderAvailability(
    List<Map<String, Object?>> slots,
  ) async =>
      api.put('vendor/service-bookings/availability', body: {'slots': slots});

  Future<List<Map<String, dynamic>>> providerServices() async =>
      _list(await api.get('vendor/service-bookings/services'));

  Future<void> saveProviderService(
    Map<String, Object?> data, {
    String? id,
  }) async {
    if (id == null) {
      await api.post('vendor/service-bookings/services', body: data);
    } else {
      await api.put('vendor/service-bookings/services/$id', body: data);
    }
  }

  Future<Map<String, dynamic>> reels() async => _map(
    await api.get('vendor/reel/list', query: {'limit': 100, 'offset': 1}),
  );

  Future<void> uploadReel({
    required String description,
    required String videoPath,
    required String thumbnailPath,
    required List<String> productIds,
  }) async => api.multipart(
    'vendor/reel/store',
    fields: {
      'description': description,
      'is_always_visible': '1',
      'tags': jsonEncode(
        productIds
            .map((id) => {'type': 'product', 'id': int.parse(id)})
            .toList(),
      ),
    },
    files: {'video': videoPath, 'thumbnail': thumbnailPath},
  );

  Future<void> publishReel(String id) async =>
      api.post('vendor/reel/$id/publish');
  Future<void> unpublishReel(String id) async =>
      api.post('vendor/reel/$id/unpublish');
  Future<void> deleteReel(String id) async =>
      api.delete('vendor/reel/delete', body: {'reel_id': id});
  Future<Map<String, dynamic>> creatorProfile() async =>
      _map(await api.get('vendor/creator/profile'));
  Future<void> updateCreatorProfile(Map<String, Object?> data) async =>
      api.put('vendor/creator/profile', body: data);
  Future<Map<String, dynamic>> creatorEarnings() async =>
      _map(await api.get('vendor/creator/earnings'));

  Future<List<Map<String, dynamic>>> campaigns() async =>
      _pagedList(await api.get('vendor/get-basic-campaigns'));
  Future<void> joinCampaign(String id) async =>
      api.put('vendor/campaign-join', body: {'campaign_id': id});
  Future<void> leaveCampaign(String id) async =>
      api.put('vendor/campaign-leave', body: {'campaign_id': id});

  Future<List<Map<String, dynamic>>> coupons() async => _list(
    await api.get('vendor/coupon/list', query: {'limit': 100, 'offset': 1}),
  );
  Future<void> createCoupon({
    required String title,
    required String code,
    required double discount,
  }) async => api.post(
    'vendor/coupon/store',
    body: {
      'code': code,
      'start_date': DateTime.now().toIso8601String(),
      'expire_date': DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String(),
      'coupon_type': 'default',
      'discount': discount,
      'discount_type': 'percent',
      'limit': 100,
      'min_purchase': 0,
      'max_discount': 0,
      'customer_ids': ['all'],
      'translations': jsonEncode([
        {'locale': 'en', 'key': 'title', 'value': title},
      ]),
    },
  );
  Future<void> updateCouponStatus(String id, bool active) async => api.post(
    'vendor/coupon/status',
    body: {'coupon_id': id, 'status': active ? 1 : 0},
  );
  Future<void> deleteCoupon(String id) async =>
      api.post('vendor/coupon/delete', body: {'coupon_id': id});

  Future<List<Map<String, dynamic>>> reviews() async =>
      _pagedList(await api.get('vendor/item/reviews'));
  Future<void> replyToReview(String reviewId, String reply) async => api.put(
    'vendor/item/reply-update',
    body: {'review_id': reviewId, 'reply': reply},
  );

  Future<List<Map<String, dynamic>>> conversations() async =>
      _pagedList(await api.get('vendor/message/list'));
  Future<List<Map<String, dynamic>>> messages(String conversationId) async =>
      _pagedList(
        await api.get(
          'vendor/message/details',
          query: {'conversation_id': conversationId},
        ),
      );
  Future<void> sendMessage(String conversationId, String message) async =>
      api.post(
        'vendor/message/send',
        body: {'conversation_id': conversationId, 'message': message},
      );

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> _pagedList(Object? value) {
    if (value is List) return _list(value);
    final map = _map(value);
    for (final key in [
      'data',
      'bookings',
      'requests',
      'campaigns',
      'reviews',
      'conversations',
      'messages',
    ]) {
      final candidate = map[key];
      if (candidate is List) return _list(candidate);
      if (candidate is Map && candidate['data'] is List) {
        return _list(candidate['data']);
      }
    }
    return const [];
  }
}
