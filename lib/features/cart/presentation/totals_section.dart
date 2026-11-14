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
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppDims.s4,
      AppDims.s3,
      AppDims.s4,
      0,
    ),
  });

  final PosState state;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final taxed = state.taxConfig.isActive && state.taxAmount > 0;

    return RepaintBoundary(
      child: Padding(
        padding: padding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: AppDims.s3),
            child: Column(
              children: [
                if (taxed && !state.taxConfig.inclusive) ...[
                  TotalRow(
                    label: context.tr.subtotal,
                    value: money(state.subtotal),
                  ),
                  const SizedBox(height: AppDims.s1),
                  TotalRow(
                    label: context.tr.taxWithRate(
                      state.taxConfig.name,
                      state.taxConfig.rateLabel,
                    ),
                    value: money(state.taxAmount),
                  ),
                  const SizedBox(height: AppDims.s2),
                  TotalRow(
                    label: context.tr.total,
                    value: money(state.total),
                    isTotal: true,
                  ),
                ] else if (taxed) ...[
                  TotalRow(
                    label: context.tr.totalInclTax(
                      state.taxConfig.name,
                      state.taxConfig.rateLabel,
                    ),
                    value: money(state.total),
                    isTotal: true,
                  ),
                  const SizedBox(height: AppDims.s2),
                  TotalRow(
                    label: context.tr.taxIncluded,
                    value: money(state.taxAmount),
                  ),
                ] else ...[
                  TotalRow(
                    label: context.tr.subtotal,
                    value: money(state.subtotal),
                  ),
                  const SizedBox(height: AppDims.s2),
                  TotalRow(
                    label: context.tr.total,
                    value: money(state.total),
                    isTotal: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
