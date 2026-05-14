import 'package:amana_pos/features/cart/presentation/total_row.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class TotalsSection extends StatelessWidget {
  final PosState state;

  const TotalsSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        0,
      ),
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surfaceSoft.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.78),
        ),
      ),
      child: Column(
        children: [
          TotalRow(
            label: 'Subtotal',
            value: money(state.subtotal),
          ),
          const SizedBox(height: AppDims.s3),
          _DashedDivider(color: colors.border),
          const SizedBox(height: AppDims.s3),
          TotalRow(
            label: 'Total',
            value: money(state.total),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 7.0;
        const dashGap = 6.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashGap)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
                (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}