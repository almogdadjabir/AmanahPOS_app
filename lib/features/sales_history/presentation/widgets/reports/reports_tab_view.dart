import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/date_range_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/day_of_week_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/peak_hours_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_status_views.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_categories_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_products_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kTrendHeight = 360.0;
const _kSmallCardH = 175.0;
const _kBottomCardH = 220.0;

/// The assembly widget for the Sales Reports tab.
///
/// Returns a [SliverMainAxisGroup] that contains the [DateRangeBar] and the
/// appropriate content based on the current [SalesReportState].
class ReportsTabView extends StatelessWidget {
  const ReportsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: DateRangeBar()),
        BlocBuilder<SalesReportBloc, SalesReportState>(
          builder: (context, state) {
            if (state.status == SalesReportBlocStatus.loading) {
              return const ReportsLoadingSkeleton();
            }

            if (state.status == SalesReportBlocStatus.failure) {
              return ReportsErrorView(
                message: state.errorMessage,
                onRetry: () =>
                    context.read<SalesReportBloc>().add(const SalesReportRefreshed()),
              );
            }

            if (state.status == SalesReportBlocStatus.loaded) {
              final report = state.report;
              if (report == null) return const ReportsEmptyView();
              return SliverToBoxAdapter(child: _ReportsContent(report: report));
            }

            // initial state — show nothing yet
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppDims.s3),
        ReportsKpiRow(summary: report.summary),
        const SizedBox(height: AppDims.s4),
        // Bento row 1: trend (2/3) + stacked small cards (1/3)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: _kTrendHeight,
                child: RevenueTrendCard(trend: report.trend),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(
                    height: _kSmallCardH,
                    child: PaymentBreakdownCard(paymentMethods: report.paymentMethods),
                  ),
                  const SizedBox(height: AppDims.s3),
                  SizedBox(
                    height: _kSmallCardH,
                    child: PeakHoursCard(peakHours: report.peakHours),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s3),
        // Bento row 2: 3 equal columns
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _kBottomCardH,
                child: TopProductsCard(products: report.topProducts),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: SizedBox(
                height: _kBottomCardH,
                child: TopCategoriesCard(categories: report.topCategories),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: SizedBox(
                height: _kBottomCardH,
                child: DayOfWeekCard(dayOfWeek: report.dayOfWeek),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s4),
      ],
    );
  }
}
