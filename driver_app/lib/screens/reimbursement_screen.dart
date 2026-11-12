import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urban_goodz_driver/screens/purchase_card_screen.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

/// "I paid, reimburse me" purchasing for Order Anywhere.
///
/// Shown instead of the purchase card when the platform runs in reimbursement
/// mode. If the backend says reimbursement is not enabled, this screen hands
/// over to the purchase-card screen so the driver always lands in the right place.
class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({
    super.key,
    required this.requestId,
    this.api,
    this.imagePicker,
  });

  final int requestId;
  final DriverApiService? api;
  final ImagePicker? imagePicker;

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> {
  late final DriverApiService _api = widget.api ?? Get.find<DriverApiService>();
  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _total = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  double _maxTotal = 0;
  double _authorized = 0;
  Map<String, dynamic>? _claim;
  XFile? _receipt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _total.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getReimbursement(widget.requestId);
      if (!mounted) return;
      if (data['enabled'] != true) {
        // Card mode: this screen does not apply.
        Get.off(() => PurchaseCardScreen(requestId: widget.requestId));
        return;
      }
      setState(() {
        _maxTotal = double.tryParse('${data['max_total']}') ?? 0;
        _authorized = double.tryParse('${data['authorized_total']}') ?? 0;
        _claim = data['claim'] is Map
            ? Map<String, dynamic>.from(data['claim'] as Map)
            : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 404 || e.statusCode == 403
            ? 'This order is not assigned to you.'
            : 'Could not load this screen. Check your connection and try again.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this screen. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked != null && mounted) setState(() => _receipt = picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  Future<void> _submit() async {
    if (_submitting) return; // collapse double taps
    final receipt = _receipt;
    if (receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take or choose a receipt photo first.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await _api.submitReimbursement(
        widget.requestId,
        receiptPath: receipt.path,
        total: double.parse(_total.text.trim()),
        notes: _notes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt sent. You will be paid back after approval.'),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.statusCode == 422 && e.message.isNotEmpty
                ? e.message
                : 'Could not send the receipt. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send the receipt. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase & reimbursement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _infoCard(),
                    const SizedBox(height: 12),
                    if (_claim != null && _claim!['status'] != 'rejected')
                      _claimCard(_claim!)
                    else ...[
                      if (_claim != null) _rejectedBanner(_claim!),
                      _form(),
                    ],
                  ],
                ),
    );
  }

  Widget _infoCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pay for the items yourself',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Spend up to \$${_maxTotal.toStringAsFixed(2)} on this order '
                '(budget \$${_authorized.toStringAsFixed(2)}). Keep your receipt, '
                'upload it here, and you are paid back with your next payout once it is approved.',
              ),
            ],
          ),
        ),
      );

  Widget _rejectedBanner(Map<String, dynamic> claim) => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Your last receipt was not approved'
            '${(claim['review_notes'] ?? '').toString().isEmpty ? '.' : ': ${claim['review_notes']}'} '
            'You can send a new one.',
          ),
        ),
      );

  Widget _claimCard(Map<String, dynamic> claim) {
    final status = '${claim['status']}';
    final label = status == 'approved' ? 'Approved' : 'Waiting for approval';
    final amount = status == 'approved' ? claim['approved_total'] : claim['claimed_total'];
    return Card(
      key: const Key('reimbursement_claim_card'),
      child: ListTile(
        leading: Icon(
          status == 'approved' ? Icons.check_circle : Icons.hourglass_top,
          color: status == 'approved' ? Colors.green : AppTheme.primary,
        ),
        title: Text('\$${double.tryParse('$amount')?.toStringAsFixed(2) ?? amount}'),
        subtitle: Text(label),
      ),
    );
  }

  Widget _form() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_receipt != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_receipt!.path), height: 180, fit: BoxFit.cover),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('reimbursement_total'),
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Receipt total (\$)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter the total on the receipt.';
                if (_maxTotal > 0 && n > _maxTotal + 0.00001) {
                  return 'Above the \$${_maxTotal.toStringAsFixed(2)} limit. Contact support first.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('reimbursement_submit'),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send receipt'),
            ),
          ],
        ),
      );
}
