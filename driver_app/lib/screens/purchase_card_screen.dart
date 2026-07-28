import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urban_goodz_driver/controllers/purchase_card_controller.dart';
import 'package:urban_goodz_driver/models/purchase_card_model.dart';
import 'package:urban_goodz_driver/screens/secure_card_reveal_screen.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

/// Order Anywhere purchase card for one assignment.
///
/// The screen shows only what the backend has actually told it. There is no
/// card artwork, no masked-PAN placeholder and no zero-substituted money: an
/// unavailable figure is labelled unavailable. There is also no issue-card
/// control — issuance is automatic once the backend has an eligible request
/// and a configured provider.
class PurchaseCardScreen extends StatefulWidget {
  const PurchaseCardScreen({
    super.key,
    required this.requestId,
    this.controllerOverride,
    this.imagePicker,
  });

  final int requestId;

  /// Test seams. Production builds its own.
  final PurchaseCardController? controllerOverride;
  final ImagePicker? imagePicker;

  @override
  State<PurchaseCardScreen> createState() => _PurchaseCardScreenState();
}

class _PurchaseCardScreenState extends State<PurchaseCardScreen> {
  late final PurchaseCardController _controller;
  late final ImagePicker _picker;

  /// Tag keeps concurrently open assignments from sharing one controller.
  late final String _tag;
  bool _ownsController = false;

  XFile? _pendingReceipt;
  final _receiptTotalController = TextEditingController();
  final _receiptNotesController = TextEditingController();
  final _receiptFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tag = 'purchase_card_${widget.requestId}';
    _picker = widget.imagePicker ?? ImagePicker();

    final override = widget.controllerOverride;
    if (override != null) {
      _controller = override;
    } else {
      _ownsController = true;
      _controller = Get.put(
        PurchaseCardController(requestId: widget.requestId),
        tag: _tag,
      );
    }
  }

  @override
  void dispose() {
    _receiptTotalController.dispose();
    _receiptNotesController.dispose();
    if (_ownsController) {
      Get.delete<PurchaseCardController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.beige,
      appBar: AppBar(
        title: const Text('Purchase Card'),
        actions: [
          Obx(
            () => IconButton(
              key: const Key('purchase_card_refresh'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh card status',
              onPressed: _controller.loading.value
                  ? null
                  : _controller.refreshCard,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final state = _controller.state.value;
          final error = _controller.error.value;

          if (_controller.loading.value && state == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _controller.refreshCard,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (error != null) _errorBanner(error),
                if (state == null)
                  _unavailableView()
                else ...[
                  _statusCard(state),
                  const SizedBox(height: 16),
                  _assignmentDetail(state),
                  const SizedBox(height: 16),
                  ..._actionsFor(state),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------- status ----------------

  Widget _statusCard(PurchaseCardState state) {
    final copy = _copyFor(state.lifecycle);

    return Card(
      key: Key('card_state_${state.lifecycle.wireValue}'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(copy.icon, color: copy.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    copy.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: copy.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(copy.body, style: const TextStyle(fontSize: 14, height: 1.45)),
            if (state.last4 != null) ...[
              const SizedBox(height: 12),
              Text(
                'Card ending ${state.last4}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Truthful copy for every lifecycle state. Nothing here implies a card
  /// exists, or that a value is known, unless the backend said so.
  _StateCopy _copyFor(CardLifecycleState state) {
    switch (state) {
      case CardLifecycleState.awaitingCustomerPayment:
        return const _StateCopy(
          'Waiting on customer payment',
          'The customer has not completed payment yet. Your purchase card will '
              'be issued automatically once payment is confirmed.',
          Icons.hourglass_empty,
          Colors.orange,
        );
      case CardLifecycleState.awaitingDriverAssignment:
        return const _StateCopy(
          'Not assigned yet',
          'This Order Anywhere request has not been assigned to a driver yet.',
          Icons.person_search_outlined,
          Colors.orange,
        );
      case CardLifecycleState.awaitingProviderConfiguration:
        return const _StateCopy(
          'Provider not configured yet.',
          'Your purchase card will be issued automatically when card services '
              'become available.\n\nNo action is required from you.',
          Icons.info_outline,
          Colors.blueGrey,
        );
      case CardLifecycleState.issuancePending:
        return const _StateCopy(
          'Card is being issued',
          'Your purchase card is being issued automatically. This screen will '
              'update once it is ready.',
          Icons.sync,
          Colors.blue,
        );
      case CardLifecycleState.cardAvailable:
        return const _StateCopy(
          'Card ready',
          'Your purchase card is ready for the approved merchant purchase.',
          Icons.check_circle_outline,
          Colors.green,
        );
      case CardLifecycleState.secureRevealAvailable:
        return const _StateCopy(
          'Card ready',
          'Open secure details when you are at the register.',
          Icons.check_circle_outline,
          Colors.green,
        );
      case CardLifecycleState.purchaseAuthorized:
        return const _StateCopy(
          'Purchase authorized',
          'The purchase has been authorized. Complete it at the merchant and '
              'submit your receipt.',
          Icons.shopping_cart_checkout,
          Colors.blue,
        );
      case CardLifecycleState.purchaseCompleted:
        return const _StateCopy(
          'Purchase complete',
          'The purchase is complete. Submit your receipt so it can be '
              'reconciled.',
          Icons.task_alt,
          Colors.green,
        );
      case CardLifecycleState.receiptRequired:
        return const _StateCopy(
          'Receipt required',
          'Submit a photo of your receipt to finish this purchase.',
          Icons.receipt_long_outlined,
          Colors.deepOrange,
        );
      case CardLifecycleState.reconciliationPending:
        return const _StateCopy(
          'Reconciliation pending',
          'Your receipt was received and is being reconciled. Nothing further '
              'is needed from you right now.',
          Icons.pending_actions,
          Colors.blue,
        );
      case CardLifecycleState.reconciled:
        return const _StateCopy(
          'Reconciled',
          'This purchase has been reconciled and closed.',
          Icons.verified_outlined,
          Colors.green,
        );
      case CardLifecycleState.frozen:
        return const _StateCopy(
          'Card frozen',
          'This card has been frozen and cannot be used. Contact support if '
              'you still need to complete the purchase.',
          Icons.ac_unit,
          Colors.redAccent,
        );
      case CardLifecycleState.canceled:
        return const _StateCopy(
          'Card canceled',
          'This purchase card has been canceled.',
          Icons.cancel_outlined,
          Colors.redAccent,
        );
      case CardLifecycleState.expired:
        return const _StateCopy(
          'Card expired',
          'This purchase card has expired and can no longer be used.',
          Icons.event_busy,
          Colors.redAccent,
        );
      case CardLifecycleState.issuanceFailed:
        return const _StateCopy(
          'Card could not be issued',
          'Automatic issuance did not succeed. Support has been notified — you '
              'can also report the problem below.',
          Icons.error_outline,
          Colors.redAccent,
        );
      case CardLifecycleState.supportRequired:
      case CardLifecycleState.unknown:
        return const _StateCopy(
          'Support needed',
          'This purchase card needs attention from support before it can be '
              'used. Please report the issue below so someone can help.',
          Icons.support_agent,
          Colors.deepOrange,
        );
    }
  }

  // ---------------- assignment detail ----------------

  Widget _assignmentDetail(PurchaseCardState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _row(
              'Order Anywhere reference',
              state.orderAnywhereReference ?? '#${state.requestId}',
            ),
            _row('Assigned to you', 'Yes'),
            _row('Merchant', state.merchantName),
            _row('Approved budget', state.approvedLimit.display),
            _row('Amount used', state.amountUsed.display),
            _row('Remaining', state.remaining.display),
            // Only when a card actually exists. Without one the status card
            // above already states the situation, and repeating it here read
            // as two separate facts.
            if (state.hasCard) _row('Card status', state.statusLabel),
            _row(
              'Receipt',
              state.receiptSubmitted ? 'Submitted' : 'Not submitted',
            ),
            if (state.receiptSubmitted)
              _row('Receipt total', state.receiptTotal.display),
            _row('Reconciliation', _reconciliationLabel(state.lifecycle)),
            if (state.failureCategory != null)
              _row('Reported issue', state.failureCategory),
            if (state.expiresAt != null)
              _row('Card expires', _date(state.expiresAt!)),
            if (state.updatedAt != null)
              _row('Last updated', _date(state.updatedAt!)),
          ],
        ),
      ),
    );
  }

  String _reconciliationLabel(CardLifecycleState state) {
    switch (state) {
      case CardLifecycleState.reconciled:
        return 'Reconciled';
      case CardLifecycleState.reconciliationPending:
        return 'Pending';
      default:
        return 'Not started';
    }
  }

  /// Renders an explicit "not available" rather than a fabricated zero or an
  /// empty cell when the backend has not supplied the value.
  Widget _row(String label, String? value) {
    final available = value != null && value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              available ? value : 'Not available',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: available ? FontWeight.w600 : FontWeight.w400,
                fontStyle: available ? FontStyle.normal : FontStyle.italic,
                color: available ? AppTheme.dark : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  // ---------------- actions ----------------

  List<Widget> _actionsFor(PurchaseCardState state) {
    final widgets = <Widget>[];

    if (state.canReveal) {
      widgets
        ..add(_revealSection())
        ..add(const SizedBox(height: 16));
    }

    if (state.canUploadReceipt) {
      widgets
        ..add(_receiptSection(state))
        ..add(const SizedBox(height: 16));
    }

    if (state.canReportFailure) {
      widgets.add(_failureSection());
    }

    return widgets;
  }

  Widget _revealSection() {
    return Card(
      key: const Key('secure_reveal_section'),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Secure card details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Card details open in a secure view for a few minutes. Screenshots '
              'are blocked and the details hide when you leave the app.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final err = _controller.revealError.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (err != null) ...[
                    Text(
                      err,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    key: const Key('open_secure_reveal'),
                    icon: const Icon(Icons.lock_outline),
                    onPressed: _controller.revealLoading.value
                        ? null
                        : _openReveal,
                    label: Text(
                      _controller.revealLoading.value
                          ? 'Opening…'
                          : 'Open secure details',
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openReveal() async {
    final session = await _controller.startReveal();
    if (session == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SecureCardRevealScreen(session: session),
      ),
    );
  }

  // ---------------- receipt ----------------

  Widget _receiptSection(PurchaseCardState state) {
    return Card(
      key: const Key('receipt_section'),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _receiptFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.receiptSubmitted ? 'Replace receipt' : 'Submit receipt',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              if (state.receiptSubmitted)
                const Text(
                  'A receipt is already on file for this purchase. Only submit '
                  'again if you need to correct it.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('receipt_camera'),
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () => _pickReceipt(ImageSource.camera),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('receipt_gallery'),
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: () => _pickReceipt(ImageSource.gallery),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (_pendingReceipt != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  key: const Key('receipt_preview'),
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_pendingReceipt!.path),
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // A preview that cannot be decoded must not take down the
                    // screen; the driver can simply pick another image.
                    errorBuilder: (_, _, _) => Container(
                      height: 170,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: const Text('Preview unavailable'),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Filename only — the full device path is never shown.
                Text(
                  _pendingReceipt!.name,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('receipt_total'),
                controller: _receiptTotalController,
                decoration: const InputDecoration(
                  labelText: 'Receipt total',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter the total shown on the receipt';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('receipt_notes'),
                controller: _receiptNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
                maxLength: 1000,
              ),
              Obx(() {
                final phase = _controller.receiptPhase.value;
                final err = _controller.receiptError.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (phase == ReceiptUploadPhase.uploading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          key: Key('receipt_uploading'),
                        ),
                      ),
                    if (phase == ReceiptUploadPhase.success)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Receipt submitted.',
                          key: Key('receipt_success'),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          err,
                          key: const Key('receipt_error'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      key: const Key('receipt_submit'),
                      onPressed: phase == ReceiptUploadPhase.uploading
                          ? null
                          : () => _submitReceipt(state),
                      child: Text(
                        phase == ReceiptUploadPhase.failed
                            ? 'Retry upload'
                            : 'Submit receipt',
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked == null || !mounted) return;
      setState(() => _pendingReceipt = picked);
      _controller.resetReceiptUpload();
    } catch (_) {
      if (!mounted) return;
      // Permission denial and camera-unavailable both land here; the driver is
      // told plainly rather than left with a dead button.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  Future<void> _submitReceipt(PurchaseCardState state) async {
    final receipt = _pendingReceipt;
    if (receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take or choose a receipt photo first.')),
      );
      return;
    }
    if (!(_receiptFormKey.currentState?.validate() ?? false)) return;

    // Replacing an accepted receipt is deliberate, so it takes a confirmation.
    var allowResubmit = false;
    if (state.receiptSubmitted) {
      allowResubmit = await _confirmResubmit();
      if (!allowResubmit) return;
    }

    final total = double.parse(_receiptTotalController.text.trim());
    final ok = await _controller.uploadReceipt(
      filePath: receipt.path,
      total: total,
      notes: _receiptNotesController.text,
      allowResubmit: allowResubmit,
    );

    if (ok && mounted) {
      setState(() => _pendingReceipt = null);
      _receiptTotalController.clear();
      _receiptNotesController.clear();
    }
  }

  Future<bool> _confirmResubmit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace receipt?'),
        content: const Text(
          'A receipt has already been submitted for this purchase. Submitting '
          'again replaces it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_resubmit'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------- failure reporting ----------------

  Widget _failureSection() {
    return Card(
      key: const Key('failure_section'),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Something wrong?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Report a problem with this purchase card and support will pick '
              'it up.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final err = _controller.failureError.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (err != null) ...[
                    Text(
                      err,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    key: const Key('report_failure'),
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: _controller.reportingFailure.value
                        ? null
                        : _openFailureSheet,
                    label: const Text('Report a problem'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openFailureSheet() async {
    final selected = await showModalBottomSheet<CardFailureCategory>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'What went wrong?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            for (final category in CardFailureCategory.values)
              ListTile(
                key: Key('failure_${category.name}'),
                title: Text(category.label),
                onTap: () => Navigator.of(ctx).pop(category),
              ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    final notes = await _promptForNotes(selected);
    if (!mounted) return;

    final ok = await _controller.reportFailure(selected, notes: notes);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent to support.')),
      );
    }
  }

  Future<String?> _promptForNotes(CardFailureCategory category) async {
    final notesController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category.label),
        content: TextField(
          key: const Key('failure_notes'),
          controller: notesController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Add any detail that will help support (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('failure_send'),
            onPressed: () => Navigator.of(ctx).pop(notesController.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    notesController.dispose();
    return result;
  }

  // ---------------- shared ----------------

  Widget _errorBanner(String message) {
    return Container(
      key: const Key('purchase_card_error'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }

  Widget _unavailableView() {
    return Padding(
      key: const Key('purchase_card_unavailable'),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.credit_card_off, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Purchase card details are not available right now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _controller.refreshCard,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _StateCopy {
  const _StateCopy(this.title, this.body, this.icon, this.color);
  final String title;
  final String body;
  final IconData icon;
  final Color color;
}
