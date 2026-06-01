import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/cart/presentation/total_row.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class TotalsSection extends StatelessWidget {
  const TotalsSection({
    super.key,
    required this.state,
  });

  final PosState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          0,
        ),
        padding: const EdgeInsetsDirectional.all(AppDims.s4),
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
              label: context.tr.subtotal,
              value: money(state.subtotal),
            ),
            const SizedBox(height: AppDims.s3),
            _DashedDivider(color: colors.border),
            const SizedBox(height: AppDims.s3),
            TotalRow(
              label: context.tr.total,
              value: money(state.total),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 7.0;
        const dashGap = 6.0;
        final dashCount =
        (constraints.maxWidth / (dashWidth + dashGap)).floor();

        if (dashCount <= 0) {
          return const SizedBox(height: 1);
        }

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