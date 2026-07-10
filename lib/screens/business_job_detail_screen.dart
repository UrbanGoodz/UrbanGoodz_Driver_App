import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/business_job_controller.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class BusinessJobDetailScreen extends StatefulWidget {
  final int jobId;
  const BusinessJobDetailScreen({super.key, required this.jobId});

  @override
  State<BusinessJobDetailScreen> createState() => _BusinessJobDetailScreenState();
}

class _BusinessJobDetailScreenState extends State<BusinessJobDetailScreen> {
  final BusinessJobController controller = Get.find<BusinessJobController>();

  @override
  void initState() {
    super.initState();
    controller.fetchDetail(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),
      body: Obx(() {
        if (controller.isDetailLoading.value && controller.selectedJob.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final job = controller.selectedJob.value;
        if (job == null) {
          return Center(
            child: Text(controller.errorMessage.value.isNotEmpty
                ? controller.errorMessage.value
                : 'Job not found'),
          );
        }
        return _body(job);
      }),
    );
  }

  Widget _body(BusinessJobModel job) {
    final ageOrMedical = job.requirements.courierCertificationRequired ||
        job.requirements.chainOfCustodyRequired ||
        job.requirements.temperatureRequirement != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(job),
          if (ageOrMedical) _ageMedicalWarning(job),
          const SizedBox(height: 16),
          _section('Pickup', job.pickup),
          const SizedBox(height: 12),
          _section('Dropoff', job.dropoff),
          const SizedBox(height: 12),
          _requirements(job),
          const SizedBox(height: 12),
          _rateCard(job),
          if (job.proof.pickupProofSubmitted) _proofChip('Pickup proof', job.proof.proofOfPickup),
          if (job.proof.deliveryProofSubmitted)
            _proofChip('Delivery proof', job.proof.proofOfDelivery),
          const SizedBox(height: 16),
          _actions(job),
        ],
      ),
    );
  }

  Widget _header(BusinessJobModel job) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  _statusChip(job.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(job.jobNumber,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (job.businessClientName != null)
                Text('Client: ${job.businessClientName}',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.dark.withAlpha(150))),
              if (job.description != null) ...[
                const SizedBox(height: 6),
                Text(job.description!,
                    style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
      );

  Widget _ageMedicalWarning(BusinessJobModel job) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                job.requirements.chainOfCustodyRequired
                    ? 'Chain-of-custody / medical handling required. Ensure proper training & handling.'
                    : job.requirements.courierCertificationRequired
                        ? 'Courier certification required for this job.'
                        : 'Temperature-controlled load. Handle per requirements.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _section(String title, JobLocation loc) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (loc.name != null) _row(Icons.business, loc.name!),
              if (loc.address != null) _row(Icons.location_on, loc.address!),
              if (loc.city != null || loc.state != null)
                _row(Icons.map, [loc.city, loc.state]
                    .where((e) => e != null)
                    .join(', ')),
              if (loc.contactName != null)
                _row(Icons.person, loc.contactName!),
              if (loc.contactPhone != null)
                _row(Icons.phone, loc.contactPhone!),
              if (loc.instructions != null)
                _row(Icons.notes, loc.instructions!),
            ],
          ),
        ),
      );

  Widget _requirements(BusinessJobModel job) {
    final r = job.requirements;
    final lines = <String>[];
    if (r.vehicleTypeNeeded != null) lines.add('Vehicle: ${r.vehicleTypeNeeded}');
    if (r.needsLiftgate) lines.add('Needs liftgate');
    if (r.needsDock) lines.add('Needs dock');
    if (r.loadType != null) lines.add('Load: ${r.loadType}');
    if (r.weight != null) lines.add('Weight: ${r.weight}');
    if (r.specialHandling != null) lines.add('Handling: ${r.specialHandling}');
    if (r.urgencyLevel != null) lines.add('Urgency: ${r.urgencyLevel}');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Requirements',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...lines.map((l) => _row(Icons.check_circle_outline, l)),
            if (lines.isEmpty)
              const Text('No special requirements.',
                  style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // Rate is DISPLAY-ONLY (not a payout). Never show payout/payment amounts.
  Widget _rateCard(BusinessJobModel job) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.attach_money, color: AppTheme.primary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Offered rate (info only)',
                      style: TextStyle(fontSize: 12)),
                  Text(job.displayRate,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _proofChip(String label, String? url) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text('$label submitted',
                    style: const TextStyle(fontSize: 13,
                        color: Colors.green, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _actions(BusinessJobModel job) {
    final c = controller;
    final s = job.status;
    final busy = c.actionLoading.value;
    return Column(
      children: [
        if (c.canAccept(s))
          _btn('Accept Job', Colors.blue, busy, () => c.accept(job.jobId)),
        if (c.canStart(s))
          _btn('Start (En Route)', Colors.blue, busy, () => c.start(job.jobId)),
        if (c.canPickup(s))
          _btn('Mark Pickup', AppTheme.primary, busy,
              () => _submitProof(job, true)),
        if (c.canDeliver(s))
          _btn('Mark Delivery', Colors.green, busy,
              () => _submitProof(job, false)),
        if (c.canReportException(s))
          _btn('Report Exception', Colors.orange, busy,
              () => _reportException(job), outline: true),
      ],
    );
  }

  Widget _btn(String label, Color color, bool busy, VoidCallback onTap,
      {bool outline = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: outline
          ? OutlinedButton(
              onPressed: busy ? null : onTap,
              style: OutlinedButton.styleFrom(
                  foregroundColor: color, side: BorderSide(color: color)),
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(label),
            )
          : ElevatedButton(
              onPressed: busy ? null : onTap,
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(label),
            ),
    );
  }

  void _submitProof(BusinessJobModel job, bool isPickup) {
    final urlCtl = TextEditingController();
    final notesCtl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(isPickup ? 'Submit Pickup Proof' : 'Submit Delivery Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtl,
              decoration: const InputDecoration(
                  labelText: 'Proof URL (https://)',
                  prefixIcon: Icon(Icons.link)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtl,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final url = urlCtl.text.trim();
              if (url.isEmpty || !url.startsWith('https://')) {
                Get.snackbar('Invalid', 'Enter an https:// URL',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white);
                return;
              }
              Get.back();
              if (isPickup) {
                controller.submitPickupProof(job.jobId,
                    proofUrl: url, notes: notesCtl.text);
              } else {
                controller.submitDeliveryProof(job.jobId,
                    proofUrl: url, notes: notesCtl.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _reportException(BusinessJobModel job) {
    final reasonCtl = TextEditingController();
    final notesCtl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Report Exception'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Reason', prefixIcon: Icon(Icons.report_problem)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtl,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtl.text.trim();
              if (reason.isEmpty) {
                Get.snackbar('Invalid', 'Reason is required',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white);
                return;
              }
              Get.back();
              controller.reportException(job.jobId,
                  reason: reason, notes: notesCtl.text);
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppTheme.accent.withAlpha(180)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.dark.withAlpha(150)))),
          ],
        ),
      );

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(status).withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(_statusLabel(status),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _statusColor(status))),
      );

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
