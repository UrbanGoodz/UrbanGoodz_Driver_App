import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/dashboard_controller.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/controllers/business_job_controller.dart';
import 'package:urban_goodz_driver/controllers/dispatch_notification_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:urban_goodz_driver/screens/active_jobs_screen.dart';
import 'package:urban_goodz_driver/screens/earnings_screen.dart';
import 'package:urban_goodz_driver/screens/notifications_screen.dart';
import 'package:urban_goodz_driver/screens/job_discovery_screen.dart';
import 'package:urban_goodz_driver/screens/capability_screen.dart';
import 'package:urban_goodz_driver/screens/business_job_detail_screen.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());
  final BusinessJobController jobsCtl = Get.put(BusinessJobController());
  final DispatchNotificationController dispatchCtl =
      Get.put(DispatchNotificationController());
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardBody(),
    ActiveJobsScreen(),
    EarningsScreen(),
    _ProfilePlaceholder(),
  ];

  @override
  void initState() {
    super.initState();
    jobsCtl.fetchJobs();
    dispatchCtl.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final DashboardController c = Get.find();
    final BusinessJobController jobsCtl = Get.find();
    final DispatchNotificationController dispatchCtl = Get.find();

    return Obx(() {
      if (c.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Urban Goodz', style: TextStyle(color: AppTheme.white)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Get.to(() => const NotificationsScreen()),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications, color: AppTheme.white, size: 26),
                    Obx(() => dispatchCtl.unreadCount.value > 0
                        ? Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                dispatchCtl.unreadCount.value.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary,
                    child: Obx(() {
                      final auth = Get.find<DriverAuthController>();
                      final initials = auth.name.value.isNotEmpty
                          ? auth.name.value[0].toUpperCase()
                          : 'D';
                      return Text(initials,
                          style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18));
                    }),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                          'Welcome back, ${Get.find<DriverAuthController>().name.value}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                      Obx(() => Text(
                          Get.find<DriverAuthController>().city.value,
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.dark.withAlpha(150)))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _MetricCard(
                    title: "Today's Earnings",
                    value: '\$${c.todayEarnings.value.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _MetricCard(
                    title: 'Active Jobs',
                    value: '${jobsCtl.jobs.length}',
                    icon: Icons.work,
                    color: AppTheme.accent,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MetricCard(
                    title: 'Acceptance',
                    value: '${c.acceptanceRate.value.toStringAsFixed(0)}%',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _MetricCard(
                    title: 'Rating',
                    value: c.rating.value.toStringAsFixed(2),
                    icon: Icons.star,
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Weekly Earnings',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8)
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: c.weeklyEarningsChart.asMap().entries.map((e) {
                    final maxVal = c.weeklyEarningsChart
                        .reduce((a, b) => a > b ? a : b);
                    final height = (e.value / maxVal) * 120;
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('\$${e.value.toInt()}',
                                style: const TextStyle(
                                    fontSize: 9, color: AppTheme.dark)),
                            const SizedBox(height: 4),
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: e.key == DateTime.now().weekday - 1
                                    ? AppTheme.primary
                                    : AppTheme.primary.withAlpha(80),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(days[e.key],
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.dark)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Jobs',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () =>
                        Get.to(() => const ActiveJobsScreen()),
                    child: const Text('See All',
                        style: TextStyle(color: AppTheme.primary)),
                  ),
                ],
              ),
              Obx(() => SizedBox(
                    height: 180,
                    child: jobsCtl.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : jobsCtl.jobs.isEmpty
                            ? const Center(
                                child: Text('No assigned business jobs yet.'))
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: jobsCtl.jobs.length > 5
                                    ? 5
                                    : jobsCtl.jobs.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final job = jobsCtl.jobs[index];
                                  return _JobCard(job: job);
                                },
                              ),
                  )),
              const SizedBox(height: 20),
              Text('Quick Actions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickAction(
                      icon: Icons.search,
                      label: 'Find Jobs',
                      color: AppTheme.primary,
                      onTap: () => Get.to(() => const JobDiscoveryScreen())),
                  _QuickAction(
                      icon: Icons.account_balance_wallet,
                      label: 'Earnings',
                      color: AppTheme.accent,
                      onTap: () {}),
                  _QuickAction(
                      icon: Icons.directions_car,
                      label: 'Vehicle',
                      color: AppTheme.primary,
                      onTap: () => Get.to(() => const CapabilityScreen())),
                  _QuickAction(
                      icon: Icons.person,
                      label: 'Profile',
                      color: AppTheme.accent,
                      onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    });
  }
}

class _JobCard extends StatelessWidget {
  final BusinessJobModel job;
  const _JobCard({required this.job});

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return AppTheme.primary;
      case 'driver_accepted':
      case 'driver_en_route':
        return Colors.blue;
      case 'picked_up':
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      default:
        return AppTheme.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => BusinessJobDetailScreen(jobId: job.jobId)),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(job.jobType.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(job.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statusLabel(job.status),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(job.status))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(job.jobNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(job.pickup.address ?? '',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.dark.withAlpha(150)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text(job.displayRate,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'driver_accepted':
        return 'Accepted';
      case 'driver_en_route':
        return 'En Route';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'delayed':
        return 'Delayed';
      default:
        return status;
    }
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.dark)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.dark.withAlpha(150))),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<DriverAuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Get.snackbar('Logged Out', 'You have exited driver mode.',
                  snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primary,
                    child: Obx(() => Text(
                          auth.name.value.isNotEmpty
                              ? auth.name.value[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        )),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Text(
                        auth.name.value,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        auth.email.value,
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.dark.withAlpha(150)),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Driver & Vehicle Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow(Icons.phone, 'Phone', auth.phone.value),
            _infoRow(Icons.location_on, 'Zone', auth.city.value),
            _infoRow(Icons.directions_car, 'Vehicle Type', auth.vehicleType.value),
            _infoRow(Icons.info, 'Vehicle Info', auth.vehicleDetails.value),
            const SizedBox(height: 20),
            const Text('Active Service Capabilities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() => Column(
                  children: [
                    if (auth.serviceOrderAnywhere.value)
                      _serviceChip('Order Anywhere'),
                    if (auth.serviceDelivery.value) _serviceChip('Store Delivery'),
                    if (auth.serviceCourier.value) _serviceChip('Courier Runs'),
                    if (auth.serviceMedicalCourier.value)
                      _serviceChip('Medical Courier'),
                    if (auth.serviceLogistics.value) _serviceChip('Logistics/Freight'),
                  ],
                )),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                auth.logout();
                Get.snackbar('Logged Out', 'You have exited driver mode.',
                    snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text('LOG OUT / RESET PORTAL',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _serviceChip(String label) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppTheme.beige,
      child: ListTile(
        leading: Icon(Icons.check_circle, color: AppTheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        dense: true,
      ),
    );
  }
}
