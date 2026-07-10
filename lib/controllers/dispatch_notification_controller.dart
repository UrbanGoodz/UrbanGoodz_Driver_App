import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/notification_model.dart';

/// Driver dispatch notification inbox. Notifications are polled (no push).
/// Supports read / read-all / dismiss.
class DispatchNotificationController extends GetxController {
  final DriverApiService _api = Get.find<DriverApiService>();

  var notifications = <DispatchNotification>[].obs;
  var unreadCount = 0.obs;
  var total = 0.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _api.getNotifications();
      notifications.value = result.$1;
      unreadCount.value = result.$2;
      total.value = result.$3;
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value = await _api.getUnreadCount();
    } catch (_) {
      // Best-effort; ignore errors on background count refresh.
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markNotificationRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final n = notifications[idx];
        notifications[idx] = DispatchNotification(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          jobType: n.jobType,
          jobId: n.jobId,
          status: 'read',
          priority: n.priority,
          requiresAction: n.requiresAction,
          reviewFlags: n.reviewFlags,
          createdAt: n.createdAt,
          readAt: n.readAt ?? DateTime.now().toIso8601String(),
          canOpen: n.canOpen,
          canDismiss: n.canDismiss,
        );
        notifications.refresh();
        if (unreadCount.value > 0) unreadCount.value--;
      }
    } catch (e) {
      Get.snackbar('Failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      notifications.value = notifications
          .map((n) => DispatchNotification(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                jobType: n.jobType,
                jobId: n.jobId,
                status: 'read',
                priority: n.priority,
                requiresAction: n.requiresAction,
                reviewFlags: n.reviewFlags,
                createdAt: n.createdAt,
                readAt: n.readAt ?? DateTime.now().toIso8601String(),
                canOpen: n.canOpen,
                canDismiss: n.canDismiss,
              ))
          .toList();
      unreadCount.value = 0;
    } catch (e) {
      Get.snackbar('Failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  Future<void> dismiss(int id) async {
    try {
      await _api.dismissNotification(id);
      notifications.removeWhere((n) => n.id == id);
      total.value = notifications.length;
      await refreshUnreadCount();
    } catch (e) {
      Get.snackbar('Failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  String _msg(Object e) => e is ApiException ? e.message : e.toString();
}
