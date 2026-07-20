import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_vendor/controllers/dashboard_controller.dart';
import 'package:urban_goodz_vendor/controllers/vendor_auth_controller.dart';
import 'package:urban_goodz_vendor/theme/app_theme.dart';
import 'package:urban_goodz_vendor/screens/orders_screen.dart';
import 'package:urban_goodz_vendor/screens/inventory_screen.dart';
import 'package:urban_goodz_vendor/screens/promotions_screen.dart';
import 'package:urban_goodz_vendor/screens/analytics_screen.dart';
import 'package:urban_goodz_vendor/screens/customer_reviews_screen.dart';
import 'package:urban_goodz_vendor/screens/revenue_tracking_screen.dart';
import 'package:urban_goodz_vendor/screens/service_bookings_screen.dart';
import 'package:urban_goodz_vendor/screens/reels_screen.dart';
import 'package:urban_goodz_vendor/screens/notifications_support_screen.dart';
import 'package:urban_goodz_vendor/screens/vendor_ai_assistant_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final RxInt _currentTab = 0.obs;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const OrdersScreen(),
    const InventoryScreen(),
    const PromotionsScreen(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: _screens[_currentTab.value],
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: _currentTab.value,
            onTap: (i) => _currentTab.value = i,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.dark.withOpacity(0.5),
            backgroundColor: AppTheme.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer),
                label: 'Promotions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final DashboardController c = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(Get.find<VendorAuthController>().businessName.value),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const VendorAiAssistantScreen()),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            onPressed: () => Get.to(() => const NotificationsSupportScreen()),
            icon: const Icon(Icons.notifications_none),
          ),
          Obx(
            () => Switch(
              value: c.storeStatus.value == 'open',
              onChanged: (_) => c.toggleStoreStatus(),
              activeColor: AppTheme.primary,
              inactiveThumbColor: Colors.grey,
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  c.storeStatus.value == 'open' ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: c.storeStatus.value == 'open'
                        ? AppTheme.accent
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => c.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStoreHeader(c),
              const SizedBox(height: 16),
              _buildMetricsGrid(c),
              const SizedBox(height: 20),
              _buildRevenueChart(c),
              const SizedBox(height: 20),
              _buildRecentOrders(c),
              const SizedBox(height: 20),
              _buildTopProducts(c),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader(DashboardController c) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.dark, AppTheme.dark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store, color: AppTheme.dark, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      Get.find<VendorAuthController>().businessName.value,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      Get.find<VendorAuthController>().city.value,
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${c.averageRating.toStringAsFixed(1)} (${c.store.value?.totalReviews ?? 0} reviews)',
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardController c) {
    return Obx(
      () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _MetricCard(
            title: "Today's Revenue",
            value: '\$${c.todayRevenue.toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: AppTheme.primary,
          ),
          _MetricCard(
            title: 'Active Orders',
            value: '${c.activeOrders.value}',
            icon: Icons.receipt,
            color: AppTheme.accent,
          ),
          _MetricCard(
            title: 'Avg Rating',
            value: c.averageRating.toStringAsFixed(1),
            icon: Icons.star,
            color: AppTheme.primary,
          ),
          _MetricCard(
            title: 'Low Stock Alerts',
            value: '${c.lowStockItems.value}',
            icon: Icons.warning_amber,
            color: c.lowStockItems.value > 0 ? Colors.red : AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(DashboardController c) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.beige.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue (Last 7 Days)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(c.revenueChart.length, (i) {
                  final maxVal = c.revenueChart.reduce((a, b) => a > b ? a : b);
                  final height = (c.revenueChart[i] / maxVal) * 120;
                  final days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '\$${(c.revenueChart[i] / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height.clamp(8.0, 120.0),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.8),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[i],
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(DashboardController c) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...c.recentOrders.map(
            (order) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.beige.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.items.length} items - \$${order.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.dark.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(order.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.dark.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(DashboardController c) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: c.topProducts.length,
              itemBuilder: (_, i) {
                final item = c.topProducts[i];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.beige.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppTheme.dark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.dark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              label: 'Orders',
              icon: Icons.receipt_long,
              onTap: () => Get.to(() => const OrdersScreen()),
            ),
            _ActionButton(
              label: 'Inventory',
              icon: Icons.inventory_2,
              onTap: () => Get.to(() => const InventoryScreen()),
            ),
            _ActionButton(
              label: 'Promotions',
              icon: Icons.local_offer,
              onTap: () => Get.to(() => const PromotionsScreen()),
            ),
            _ActionButton(
              label: 'Analytics',
              icon: Icons.analytics,
              onTap: () => Get.to(() => const AnalyticsScreen()),
            ),
            _ActionButton(
              label: 'Reviews',
              icon: Icons.reviews,
              onTap: () => Get.to(() => const CustomerReviewsScreen()),
            ),
            _ActionButton(
              label: 'Revenue',
              icon: Icons.account_balance_wallet,
              onTap: () => Get.to(() => const RevenueTrackingScreen()),
            ),
            _ActionButton(
              label: 'Bookings',
              icon: Icons.calendar_today,
              onTap: () => Get.to(() => const ServiceBookingsScreen()),
            ),
            _ActionButton(
              label: 'Reels',
              icon: Icons.videocam,
              onTap: () => Get.to(() => const ReelsScreen()),
            ),
            _ActionButton(
              label: 'Support',
              icon: Icons.support_agent,
              onTap: () => Get.to(() => const NotificationsSupportScreen()),
            ),
          ],
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.beige.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.dark.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String label;
    switch (status) {
      case 'pending':
        bgColor = Colors.orange;
        label = 'Pending';
        break;
      case 'confirmed':
        bgColor = AppTheme.accent;
        label = 'Confirmed';
        break;
      case 'preparing':
        bgColor = AppTheme.primary;
        label = 'Preparing';
        break;
      case 'ready':
        bgColor = AppTheme.accent;
        label = 'Ready';
        break;
      case 'completed':
        bgColor = AppTheme.primary;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.beige.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<VendorAuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Profile')),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primary,
                child: Text(
                  auth.businessName.value.isNotEmpty
                      ? auth.businessName.value[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 40,
                    color: AppTheme.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                auth.businessName.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.addressNotes.value,
                style: TextStyle(color: AppTheme.dark.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),
              _ProfileRow(label: 'Owner', value: auth.ownerName.value),
              _ProfileRow(label: 'Phone', value: auth.phone.value),
              _ProfileRow(label: 'Email', value: auth.email.value),
              _ProfileRow(label: 'Category', value: auth.businessType.value),
              _ProfileRow(label: 'Zone', value: auth.city.value),
              const SizedBox(height: 24),
              const Text(
                '🚚 Vendor Delivery & Driver Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.beige.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeliveryStatusRow(
                      'Vendor Delivery',
                      'Pending Urban Goodz Approval',
                      Colors.orange,
                    ),
                    _buildDeliveryStatusRow(
                      'Active Driver',
                      'Pending Approval',
                      Colors.orange,
                    ),
                    _buildDeliveryStatusRow(
                      'Delivery Fee Payout',
                      'Paid to Urban Goodz Driver',
                      Colors.grey.shade600,
                    ),
                    const Divider(height: 20),
                    const Text(
                      'Delivery pricing settings are controlled from the Master Admin panel only. Vendor cannot globally change delivery charges.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.dark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out / Reset Tester Mode'),
                onTap: () {
                  auth.logout();
                  Get.snackbar(
                    'Logged Out',
                    'You have exited vendor mode.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.dark.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppTheme.dark)),
          ),
        ],
      ),
    );
  }
}
