import 'package:flutter/material.dart';

class UrbanGoodzPreviewBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const UrbanGoodzPreviewBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
