import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateRangeBar extends StatelessWidget {
  const DateRangeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final preset = context.select((SalesReportBloc b) => b.state.preset);
    final colors = context.appColors;

    void dispatch(ReportPreset p) =>
        context.read<SalesReportBloc>().add(SalesReportRangeChanged(preset: p));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDims.s2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PresetChip(
              label: context.tr.today,
              active: preset == ReportPreset.today,
              onTap: () => dispatch(ReportPreset.today),
            ),
            const SizedBox(width: AppDims.s2),
            _PresetChip(
              label: context.tr.yesterday,
              active: preset == ReportPreset.yesterday,
              onTap: () => dispatch(ReportPreset.yesterday),
            ),
            const SizedBox(width: AppDims.s2),
            _PresetChip(
              label: context.tr.thisWeek,
              active: preset == ReportPreset.thisWeek,
              onTap: () => dispatch(ReportPreset.thisWeek),
            ),
            const SizedBox(width: AppDims.s2),
            _PresetChip(
              label: context.tr.thisMonth,
              active: preset == ReportPreset.thisMonth,
              onTap: () => dispatch(ReportPreset.thisMonth),
            ),
            const SizedBox(width: AppDims.s2),
            _CustomRangeButton(preset: preset),
            const SizedBox(width: AppDims.s3),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: context.tr.reportsRefresh,
              onPressed: () => context
                  .read<SalesReportBloc>()
                  .add(const SalesReportRefreshed()),
              color: colors.textSecondary,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2,
        ),
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: active ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.sm200(context).copyWith(
            color: active ? Colors.white : colors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CustomRangeButton extends StatelessWidget {
  const _CustomRangeButton({required this.preset});
  final ReportPreset preset;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = preset == ReportPreset.custom;
    final state = context.watch<SalesReportBloc>().state;

    String label = context.tr.selectDateRange;
    if (isActive && state.customRange != null) {
      final r = state.customRange!;
      String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
      label = '${fmt(r.start)} – ${fmt(r.end)}';
    }

    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: state.customRange,
        );
        if (picked != null && context.mounted) {
          context.read<SalesReportBloc>().add(
            SalesReportRangeChanged(
              preset: ReportPreset.custom,
              customRange: picked,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2,
        ),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: isActive ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 14,
              color: isActive ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.sm200(context).copyWith(
                color: isActive ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
