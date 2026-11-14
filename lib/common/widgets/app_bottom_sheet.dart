import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

/// Thin wrapper kept for existing call sites; renders the shared [AppSheet].
class AppBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final String? logoAsset;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      logoAsset: logoAsset,
      keyboardSafe: false,
      showGrabber: false,
      child: child,
    );
  }
}
