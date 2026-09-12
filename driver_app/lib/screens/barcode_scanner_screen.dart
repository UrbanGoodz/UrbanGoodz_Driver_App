import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

/// Camera barcode scanner.
///
/// Pops with the decoded barcode string, or null if the driver backs out.
/// Callers treat the result exactly like a typed barcode, so the scan endpoints
/// and the manifest matching logic did not have to change at all.
///
/// Two behaviours here are deliberate rather than incidental:
///
///  * **One result, then stop.** A barcode sitting in frame fires the detect
///    callback on every frame. Without the `_handled` latch a single package
///    would post several scans to the server, which for a pickup scan reads as
///    the driver loading the same parcel repeatedly.
///
///  * **A visible manual fallback.** Warehouse labels get scuffed, wet, or
///    torn, and a driver holding a damaged parcel cannot be left with no way
///    to record it. The old screen was manual-only; this keeps manual as the
///    escape hatch rather than deleting it.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key, this.title = 'Scan package'});

  final String title;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    // The formats a parcel label actually carries. Narrowing the set makes
    // detection faster and stops the camera locking onto unrelated codes.
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Guards against the same barcode being returned many times per second.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  Future<void> _enterManually() async {
    final controller = TextEditingController();

    final entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter barcode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Barcode from the label',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Use'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (entered != null && entered.isNotEmpty) {
      Navigator.of(context).pop(entered);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              // A denied camera permission is the common case and must not
              // look like a crash - the driver still needs a way through.
              return _CameraUnavailable(
                message: switch (error.errorCode) {
                  MobileScannerErrorCode.permissionDenied =>
                    'Camera permission is off. Allow camera access for Urban Goodz Driver in Settings, or enter the barcode by hand.',
                  MobileScannerErrorCode.unsupported =>
                    'This device cannot scan. Enter the barcode by hand.',
                  _ => 'Camera unavailable. Enter the barcode by hand.',
                },
                onManual: _enterManually,
              );
            },
          ),

          // Aiming guide.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point the camera at the package label',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _enterManually,
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    label: const Text(
                      'Damaged label? Enter it by hand',
                      style: TextStyle(color: Colors.white),
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
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.message, required this.onManual});

  final String message;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography, color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: onManual,
            icon: const Icon(Icons.keyboard, color: Colors.white),
            label: const Text('Enter barcode', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
