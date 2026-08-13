import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/marketplace_orders_controller.dart';
import 'package:urban_goodz_driver/models/marketplace_order.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/theme/ug_brand.dart';

/// Marketplace deliveries assigned to this driver.
///
/// Restaurant, grocery, retail, home-based and pharmacy orders all use one
/// lifecycle, so they share one screen rather than a screen per module.
class MarketplaceOrdersScreen extends StatelessWidget {
  const MarketplaceOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MarketplaceOrdersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Deliveries'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: c.refreshOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: c.refreshOrders,
          child: Column(
            children: [
              if (c.errorMessage.value != null)
                _Banner(
                  text: c.errorMessage.value!,
                  color: const Color(0xFFD32F2F),
                  icon: Icons.error_outline,
                ),
              if (c.lastActionMessage.value != null)
                _Banner(
                  text: c.lastActionMessage.value!,
                  color: AppTheme.primary,
                  icon: Icons.info_outline,
                ),
              Expanded(
                child: c.orders.isEmpty
                    ? _EmptyState(onRefresh: c.refreshOrders)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: c.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _OrderCard(order: c.orders[i]),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Center(child: UgBrand.appMarkImage(size: 72)),
        const SizedBox(height: 20),
        const Text(
          'No marketplace deliveries right now',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Assigned orders appear here as soon as a store sends one your way.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Banner({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MarketplaceOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MarketplaceOrdersController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.storeName ?? 'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(status: order.orderStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#${order.id} · ${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · '
            '\$${order.orderAmount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (order.deliveryAddress != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 16, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                '${order.paymentMethod.replaceAll('_', ' ')} · ${order.paymentStatus}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (order.nextDriverStatus != null)
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: c.isActing.value
                      ? null
                      : () => _act(context, c, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UgBrand.orange,
                    foregroundColor: UgBrand.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    order.nextDriverActionLabel.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            )
          else
            const Text(
              'No driver action available for this status.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    MarketplaceOrdersController c,
    MarketplaceOrder order,
  ) async {
    // Delivery is the one step that can require a code from the customer.
    if (order.nextDriverStatus == 'delivered') {
      final otp = await _askForOtp(context, c, order);
      if (otp == null) return;
      await c.advance(order, otp: otp);
      return;
    }

    await c.advance(order);
  }

  Future<String?> _askForOtp(
    BuildContext context,
    MarketplaceOrdersController c,
    MarketplaceOrder order,
  ) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask the customer for the code shown in their app, then enter it '
              'to complete the delivery.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => c.sendDeliveryOtp(order),
              icon: const Icon(Icons.sms_outlined, size: 18),
              label: const Text('Resend code to customer'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Complete delivery'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    'pending' => Colors.orange,
    'confirmed' => Colors.blue,
    'processing' || 'handover' => Colors.purple,
    'picked_up' => Colors.teal,
    'delivered' => Colors.green,
    'canceled' || 'refunded' => Colors.red,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(110)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
