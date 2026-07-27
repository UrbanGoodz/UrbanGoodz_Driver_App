import 'package:get/get.dart';
import 'package:urban_goodz_vendor/controllers/inventory_controller.dart';
import 'package:urban_goodz_vendor/controllers/orders_controller.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/models/inventory_item_model.dart';
import 'package:urban_goodz_vendor/models/vendor_order_model.dart';
import 'package:urban_goodz_vendor/models/vendor_store_model.dart';
import 'package:urban_goodz_vendor/repositories/vendor_repository.dart';
import 'package:urban_goodz_vendor/services/vendor_api_client.dart';

class DashboardController extends GetxController {
  final repository = Get.find<VendorRepository>();
  final store = Rx<VendorStoreModel?>(null);
  final todayRevenue = 0.0.obs;
  final weeklyRevenue = 0.0.obs;
  final monthlyRevenue = 0.0.obs;
  final totalOrders = 0.obs;
  final activeOrders = 0.obs;
  final pendingBookings = 0.obs;
  final averageRating = 0.0.obs;
  final lowStockItems = 0.obs;
  final recentOrders = <VendorOrderModel>[].obs;
  final topProducts = <InventoryItemModel>[].obs;
  /// Daily revenue for the last 7 days. No endpoint supplies this series yet,
  /// so it stays all zeros for every vendor - see [hasNoRevenue].
  final revenueChart = List<double>.filled(7, 0).obs;
  final storeStatus = 'closed'.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final notificationCount = 0.obs;

  /// True when no day in the window carries usable revenue, including when the
  /// series is empty. The chart renders an empty state instead of bars.
  bool get hasNoRevenue => !revenueChart.any(_isPlottable);

  /// Relative bar heights for [values]: each is `0.0..1.0`, where `1.0` is the
  /// largest plottable day in the window.
  ///
  /// Scaling must never divide by a non-positive maximum. An all-zero series
  /// makes `value / max` compute `0 / 0` -> NaN, and `num.clamp` does not
  /// preserve NaN: `double.nan.clamp(8, 120)` returns the *upper* bound, 120.
  /// So every bar was silently drawn at full height instead of no height.
  /// A vendor signing in for the first time has exactly that series, so this
  /// was the default view.
  ///
  /// Full height then did not fit: 120px of bar plus 8px of spacers plus two
  /// 9pt labels needs ~154px inside a 140px row, which is the 14px RenderFlex
  /// overflow. Fractions rather than pixels fix that half - the caller gives
  /// them to a FractionallySizedBox filling whatever space the row has left
  /// after its labels, so a bar cannot outgrow its container whatever the text
  /// measures.
  static List<double> barFractions(List<double> values) {
    var max = 0.0;
    for (final value in values) {
      if (_isPlottable(value) && value > max) max = value;
    }
    if (max <= 0) return List<double>.filled(values.length, 0);
    return [
      for (final value in values)
        _isPlottable(value) ? (value / max).clamp(0.0, 1.0) : 0.0,
    ];
  }

  /// A value can be drawn only if it is a real, positive amount. NaN and
  /// infinity reach here when the API sends them as strings, since
  /// `double.tryParse` accepts both.
  static bool _isPlottable(double value) => value.isFinite && value > 0;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final profile = await repository.profile();
      final rawStore = profile['stores'];
      final storeJson = rawStore is Map
          ? Map<String, dynamic>.from(rawStore)
          : <String, dynamic>{};
      final orderRows = await repository.currentOrders();
      final itemResponse = await repository.items(limit: 25);
      final notifications = await repository.notifications();
      final itemRows = itemResponse['items'];
      final mappedOrders = orderRows.map(OrdersController.fromJson).toList();
      final mappedItems = itemRows is List
          ? itemRows
                .whereType<Map>()
                .map(
                  (row) => InventoryController.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList()
          : <InventoryItemModel>[];

      final schedules = storeJson['schedules'];
      String openTime = '';
      String closeTime = '';
      if (schedules is List && schedules.isNotEmpty && schedules.first is Map) {
        openTime = schedules.first['opening_time']?.toString() ?? '';
        closeTime = schedules.first['closing_time']?.toString() ?? '';
      }
      final active = _bool(storeJson['active']);
      store.value = VendorStoreModel(
        id: storeJson['id']?.toString() ?? '',
        name: storeJson['name']?.toString() ?? '',
        description: storeJson['description']?.toString() ?? '',
        address: storeJson['address']?.toString() ?? '',
        phone: storeJson['phone']?.toString() ?? '',
        email: storeJson['email']?.toString() ?? '',
        logoUrl: storeJson['logo_full_url']?.toString() ?? '',
        bannerUrl: storeJson['cover_photo_full_url']?.toString() ?? '',
        isOpen: active,
        openTime: openTime,
        closeTime: closeTime,
        rating: _double(storeJson['avg_rating'] ?? storeJson['rating']),
        reviewCount: _int(
          storeJson['rating_count'] ?? storeJson['reviews_count'],
        ),
        totalOrders: _int(profile['order_count']),
        totalRevenue: _double(profile['total_earning']),
        joinDate: profile['created_at']?.toString() ?? '',
        totalReviews: _int(storeJson['reviews_count']),
        hours: '$openTime - $closeTime',
      );
      storeStatus.value = active ? 'open' : 'closed';
      todayRevenue.value = _double(profile['todays_earning']);
      weeklyRevenue.value = _double(profile['this_week_earning']);
      monthlyRevenue.value = _double(profile['this_month_earning']);
      totalOrders.value = _int(profile['order_count']);
      activeOrders.value = mappedOrders.length;
      averageRating.value = store.value?.rating ?? 0;
      lowStockItems.value = mappedItems
          .where((item) => item.isLowStock || item.isOutOfStock)
          .length;
      recentOrders.assignAll(mappedOrders.take(5));
      topProducts.assignAll(mappedItems.where((item) => item.isActive).take(5));
      notificationCount.value = notifications.length;
      Get.find<VendorAuthController>().storeStatus.value = storeStatus.value;
    } on VendorApiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleStoreStatus() async {
    try {
      await repository.toggleStoreStatus();
      await fetchDashboard();
    } on VendorApiException catch (error) {
      errorMessage.value = error.message;
      Get.snackbar('Store status failed', error.message);
    }
  }

  Future<void> refresh() => fetchDashboard();

  static bool _bool(Object? value) =>
      value == true || value == 1 || value?.toString() == '1';
  static double _double(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
  static int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
}
