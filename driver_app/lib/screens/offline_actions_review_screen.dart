import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/dedicated_route_controller.dart';
import 'package:urban_goodz_driver/screens/delivery_photo_capture_screen.dart';
import 'package:urban_goodz_driver/screens/signature_capture_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

/// Lists the queued actions the server rejected outright (4xx) — things
/// that will never succeed by simply retrying, so they sit here instead of
/// being silently discarded or retried forever. Each one offers "Fix and
/// retry" (recapture proof for a dropoff, or just resend for anything
/// else) and "Discard" (with confirmation).
class OfflineActionsReviewScreen extends StatelessWidget {
  const OfflineActionsReviewScreen({super.key});

  String _actionLabel(String type) {
    switch (type) {
      case 'dropoff':
        return 'Delivery scan';
      case 'pickup':
        return 'Intake scan';
      case 'exception':
        return 'Delivery exception';
      case 'start':
        return 'Start route';
      case 'complete':
        return 'Complete route';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DedicatedRouteController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Actions Needing Attention')),
      body: Obx(() {
        final items = controller.needsAttentionActions;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nothing needs your attention right now.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) => _ActionCard(
            action: items[index],
            actionLabel: _actionLabel(items[index]['type'] as String),
          ),
        );
      }),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final Map<String, dynamic> action;
  final String actionLabel;
  const _ActionCard({required this.action, required this.actionLabel});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DedicatedRouteController>();
    final data = widget.action['data'] as Map<String, dynamic>;
    final type = widget.action['type'] as String;
    final barcode = data['barcode']?.toString() ?? '';
    final lastError = widget.action['last_error']?.toString() ?? 'The server rejected this request.';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (barcode.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Package: $barcode', style: TextStyle(color: AppTheme.dark.withAlpha(180))),
            ],
            const SizedBox(height: 6),
            Text(
              lastError,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _discard(controller),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: _busy ? null : () => _fixAndRetry(controller, type),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Fix and retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _discard(DedicatedRouteController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this action?'),
        content: const Text(
          'This cannot be sent and will be permanently removed. The package will stay marked as needing action.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.discardOfflineAction(widget.action);
    }
  }

  Future<void> _fixAndRetry(DedicatedRouteController controller, String type) async {
    if (type != 'dropoff') {
      setState(() => _busy = true);
      final ok = await controller.retrySimpleAction(widget.action);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Sent successfully.' : 'Still rejected — see the message above.')),
      );
      return;
    }

    // Dropoff: the rejection is almost always missing proof, so send the
    // driver straight to capturing it again rather than making them guess.
    final photo = await Navigator.of(context, rootNavigator: true).push<File?>(
      MaterialPageRoute(builder: (_) => const DeliveryPhotoCaptureScreen()),
    );
    if (!mounted) return;
    final signature = await Navigator.of(context, rootNavigator: true).push<File?>(
      MaterialPageRoute(builder: (_) => const SignatureCaptureScreen()),
    );
    if (!mounted) return;
    if (photo == null && signature == null) return;

    setState(() => _busy = true);
    final ok = await controller.retryDropoffWithNewProof(
      widget.action,
      photoFile: photo,
      signatureFile: signature,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Delivery recorded.' : 'Still rejected — see the message above.')),
    );
  }
}
