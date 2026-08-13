import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/marketplace_order.dart';
import 'package:urban_goodz_driver/services/marketplace_order_service.dart';

class MarketplaceOrdersController extends GetxController {
  final MarketplaceOrderService _service;

  MarketplaceOrdersController({MarketplaceOrderService? service})
    : _service = service ?? MarketplaceOrderService();

  final orders = <MarketplaceOrder>[].obs;
  final isLoading = false.obs;
  final isActing = false.obs;
  final errorMessage = RxnString();
  final lastActionMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshOrders();
  }

  Future<void> refreshOrders() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      orders.assignAll(await _service.currentOrders());
    } on MarketplaceOrderException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Could not load your orders. Check your connection.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Advance an order. Returns true when the backend accepted the change.
  ///
  /// A confirmation-model mismatch is reported as a message rather than an
  /// error: on a platform where the store confirms, the driver simply has no
  /// confirm step, and telling them the request "failed" would be misleading.
  Future<bool> advance(
    MarketplaceOrder order, {
    String? otp,
    String? reason,
  }) async {
    final next = order.nextDriverStatus;
    if (next == null) return false;

    isActing.value = true;
    errorMessage.value = null;
    lastActionMessage.value = null;

    try {
      await _service.updateStatus(order.id, next, otp: otp, reason: reason);
      lastActionMessage.value = 'Order #${order.id} is now ${next.replaceAll('_', ' ')}.';
      await refreshOrders();
      return true;
    } on MarketplaceOrderException catch (e) {
      if (e.isConfirmationModelMismatch) {
        lastActionMessage.value =
            'The store confirms orders on this platform. Wait for the store, then pick up.';
      } else if (e.isOtpMismatch) {
        errorMessage.value = 'That delivery code does not match. Ask the customer to read it again.';
      } else if (e.isNotAssigned) {
        errorMessage.value = 'This order is no longer assigned to you.';
      } else {
        errorMessage.value = e.message;
      }
      return false;
    } catch (_) {
      errorMessage.value = 'Could not update the order. Check your connection.';
      return false;
    } finally {
      isActing.value = false;
    }
  }

  Future<void> sendDeliveryOtp(MarketplaceOrder order) async {
    try {
      await _service.sendDeliveryOtp(order.id);
      lastActionMessage.value = 'Delivery code sent to the customer.';
    } on MarketplaceOrderException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Could not send the delivery code.';
    }
  }
}
