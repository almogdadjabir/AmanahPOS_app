import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SaleShimmer extends StatefulWidget {
  const SaleShimmer({super.key});
  @override
  State<SaleShimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<SaleShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s8),
        itemCount: 8,
        itemBuilder: (_, i) {
          final phase   = ((i * 0.15) + _ctrl.value) % 1.0;
          final opacity = 0.35 + (phase < 0.5 ? phase : 1.0 - phase) * 0.35;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDims.s2),
            child: Opacity(
              opacity: opacity,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}