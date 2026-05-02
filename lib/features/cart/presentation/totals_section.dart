import 'package:amana_pos/features/cart/presentation/total_row.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class TotalsSection extends StatelessWidget {
  final PosState state;

  const TotalsSection({super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(top: AppDims.s3),
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        children: [
          TotalRow(
            label: 'Subtotal',
            value: money(state.subtotal),
          ),
          const SizedBox(height: AppDims.s2),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: AppDims.s2),
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