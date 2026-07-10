import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/dispatch_notification_controller.dart';
import 'package:urban_goodz_driver/screens/business_job_detail_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DispatchNotificationController controller =
      Get.find<DispatchNotificationController>();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Notifications'),
        actions: [
          Obx(() => controller.unreadCount.value > 0
              ? TextButton(
                  onPressed: () => controller.markAllRead(),
                  child: const Text('Mark all read',
                      style: TextStyle(color: AppTheme.white)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off,
                    size: 64, color: AppTheme.dark.withAlpha(60)),
                const SizedBox(height: 16),
                const Text('No notifications',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = controller.notifications[index];
              return _card(n);
            },
          ),
        );
      }),
    );
  }

  Widget _card(n) {
    final isUnread = n.status != 'read';
    return Dismissible(
      key: Key('notif-${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        controller.dismiss(n.id);
        return false; // we manage the list ourselves
      },
      child: Card(
        color: isUnread ? AppTheme.primary.withAlpha(15) : AppTheme.white,
        child: ListTile(
          leading: Icon(
            n.isHighPriority ? Icons.priority_high : Icons.notifications,
            color: n.isHighPriority ? Colors.red : AppTheme.primary,
          ),
          title: Row(
            children: [
              Expanded(
                  child: Text(n.title,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.blue, shape: BoxShape.circle),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.body),
              if (n.isAgeOrMedical)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Age / medical review required',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          isThreeLine: true,
          trailing: n.canDismiss
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => controller.dismiss(n.id),
                )
              : null,
          onTap: () {
            if (isUnread) controller.markRead(n.id);
            if (n.jobId != null &&
                (n.jobType == 'business_courier' ||
                    n.jobType == 'business_courier_assigned' ||
                    n.jobType == 'business_courier_updated')) {
              Get.to(() => BusinessJobDetailScreen(jobId: n.jobId!));
            }
          },
        ),
      ),
    );
  }
}
