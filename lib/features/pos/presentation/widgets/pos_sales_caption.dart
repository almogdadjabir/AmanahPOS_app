import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class PosSalesCaption extends StatelessWidget {
  const PosSalesCaption({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
      buildWhen: (prev, curr) =>
      prev.status != curr.status || prev.summary != curr.summary,
      builder: (context, state) {
        final summary = state.summary;

        final amount = summary?.today.grossSalesAmount ?? 0;
        final salesCount = summary?.today.salesCount ?? 0;
        final currency = summary?.currency ?? 'SDG';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s2,
            AppDims.s4,
            0,
          ),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
              decoration: BoxDecoration(
                color: colors.surfaceSoft.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.72),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    SolarIconsOutline.chart,
                    size: 15,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Today: ${_money(amount)} $currency · $salesCount sale${salesCount == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(
                    SolarIconsOutline.altArrowRight,
                    size: 15,
                    color: colors.textHint,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _money(double value) {
    final raw = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

    return raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );
  }
}