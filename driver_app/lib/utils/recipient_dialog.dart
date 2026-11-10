import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Asks who received a delivery before it is completed.
///
/// Resolves to `null` when the driver cancels (do NOT complete the job), or
/// to the trimmed name — possibly empty — when they confirm. The name is
/// optional for now; the server will require it for some job types later and
/// answers 422 `recipient_required`, which the controller surfaces.
Future<String?> askDeliveryRecipient() {
  return Get.dialog<String>(const _RecipientDialog());
}

class _RecipientDialog extends StatefulWidget {
  const _RecipientDialog();

  @override
  State<_RecipientDialog> createState() => _RecipientDialogState();
}

class _RecipientDialogState extends State<_RecipientDialog> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_ctl.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Who received it?'),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        maxLength: 120,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Who received it?',
          hintText: 'Name of the person who received it',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Complete delivery'),
        ),
      ],
    );
  }
}
