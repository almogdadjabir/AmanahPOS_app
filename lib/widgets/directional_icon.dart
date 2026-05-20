import 'package:flutter/material.dart';

/// Wraps any icon and optionally mirrors it horizontally in RTL layouts.
///
/// Use for directional icons (←/→ navigation, chevrons) that should flip
/// in Arabic. Do NOT use for vertical icons (↑/↓ dropdowns) — keep those
/// as plain [Icon] widgets.
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final bool flipInRtl;
  final double? size;
  final Color? color;

  const DirectionalIcon({
    super.key,
    required this.icon,
    this.flipInRtl = true,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, size: size, color: color);
    if (flipInRtl && Directionality.of(context) == TextDirection.rtl) {
      return Transform.scale(scaleX: -1, child: child);
    }
    return child;
  }
}
