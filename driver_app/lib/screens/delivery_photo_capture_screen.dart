import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

/// Opens the camera, then shows a preview with "Retake"/"Use photo" before
/// returning the captured [File]. Pops `null` if the driver backs out at
/// either stage (camera cancelled, or declines the preview without retaking).
class DeliveryPhotoCaptureScreen extends StatefulWidget {
  const DeliveryPhotoCaptureScreen({super.key, this.imagePicker});

  /// Test seam. Production builds its own.
  final ImagePicker? imagePicker;

  @override
  State<DeliveryPhotoCaptureScreen> createState() => _DeliveryPhotoCaptureScreenState();
}

class _DeliveryPhotoCaptureScreenState extends State<DeliveryPhotoCaptureScreen> {
  late final ImagePicker _picker;
  XFile? _captured;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    setState(() => _capturing = true);
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (!mounted) return;
      if (shot == null) {
        Navigator.of(context).pop(null);
        return;
      }
      setState(() {
        _captured = shot;
        _capturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the camera: $e')),
      );
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Photo')),
      body: _capturing
          ? const Center(child: CircularProgressIndicator())
          : _captured == null
              ? const Center(child: Text('Camera cancelled.'))
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.file(File(_captured!.path), fit: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _captured = null;
                                _capture();
                              }),
                              child: const Text('Retake'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                              onPressed: () => Navigator.of(context).pop(File(_captured!.path)),
                              child: const Text('Use photo', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
