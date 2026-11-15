import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_hero.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_payments_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_peak_cards.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_ranked_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_range_sheet.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_states.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_trend_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_filter_chip.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Sales reports: period chips, one net-sales card, then one column of cards.
/// Needs a [SalesReportBloc] above it (see RouteStrings.reportsScreen).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _updatedAt;

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    final bloc = context.read<SalesReportBloc>()
      ..add(const SalesReportRefreshed());
    await bloc.stream
        .firstWhere((s) => s.status != SalesReportBlocStatus.loading)
        .timeout(const Duration(seconds: 8), onTimeout: () => bloc.state);
  }

  Future<void> _pickCustom(SalesReportState state) async {
    final bloc = context.read<SalesReportBloc>();
    final range = await showReportRangeSheet(
      context,
      initial: state.customRange,
    );
    if (range == null) return;
    bloc.add(
      SalesReportRangeChanged(preset: ReportPreset.custom, customRange: range),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final bottom = MediaQuery.viewPaddingOf(context).bottom + AppDims.s6;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<SalesReportBloc, SalesReportState>(
          listenWhen: (a, b) =>
              a.report != b.report && b.status == SalesReportBlocStatus.loaded,
          listener: (_, _) => _updatedAt = DateTime.now(),
          builder: (context, state) {
            return Column(
              children: [
                const _NavBar(),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      CupertinoSliverRefreshControl(onRefresh: _refresh),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDims.s4,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AppLargeTitle(title: tr.rpTitle),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: ReportChipsHeaderDelegate(
                          background: colors.background,
                          child: _Chips(
                            state: state,
                            onPreset: (p) => context
                                .read<SalesReportBloc>()
                                .add(SalesReportRangeChanged(preset: p)),
                            onCustom: () => _pickCustom(state),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppDims.s4,
                          2,
                          AppDims.s4,
                          bottom,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _Body(state: state, updatedAt: _updatedAt),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      DirectionalIcon(
                        icon: PhosphorIconsRegular.caretLeft,
                        size: 22,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.tr.navHome,
                        style: TextStyle(fontSize: 17, color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final SalesReportState state;
  final ValueChanged<ReportPreset> onPreset;
  final VoidCallback onCustom;

  const _Chips({
    required this.state,
    required this.onPreset,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final items = <(ReportPreset, String)>[
      (ReportPreset.today, tr.rpToday),
      (ReportPreset.yesterday, tr.rpYesterday),
      (ReportPreset.thisWeek, tr.rpWeek),
      (ReportPreset.thisMonth, tr.rpMonth),
      (ReportPreset.custom, tr.rpCustom),
    ];

    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s4, vertical: 10),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDims.s2),
          AppFilterChip(
            label: items[i].$2,
            selected: state.preset == items[i].$1,
            showCaret: items[i].$1 == ReportPreset.custom,
            onTap: items[i].$1 == ReportPreset.custom
                ? onCustom
                : () => onPreset(items[i].$1),
          ),
        ],
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final SalesReportState state;
  final DateTime? updatedAt;

  const _Body({required this.state, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SalesReportBlocStatus.initial:
      case SalesReportBlocStatus.loading:
        return const ReportSkeleton();
      case SalesReportBlocStatus.failure:
        return ReportMessageCard.error(
          context,
          onRetry: () =>
              context.read<SalesReportBloc>().add(const SalesReportRefreshed()),
        );
      case SalesReportBlocStatus.loaded:
        final report = state.report;
        if (report == null || report.isEmpty) {
          return ReportMessageCard.empty(context);
        }
        return _Content(report: report, updatedAt: updatedAt);
    }
  }
}

class _Content extends StatelessWidget {
  final SalesReport report;
  final DateTime? updatedAt;

  const _Content({required this.report, required this.updatedAt});

  int get _days {
    final from = DateTime.tryParse(report.rangeFrom);
    final to = DateTime.tryParse(report.rangeTo);
    if (from == null || to == null) return report.trend.points.length;
    return to.difference(from).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final days = _days;
    final hasHours = report.peakHours.any((h) => h.amount > 0);
    final hasDays = report.dayOfWeek.any((d) => d.amount > 0);
    final time = DateFormat(
      'HH:mm',
      'en_US',
    ).format(updatedAt ?? DateTime.now());

    return Column(
      children: [
        ReportHero(summary: report.summary),
        if (report.trend.points.isNotEmpty)
          ReportTrendCard(trend: report.trend),
        if (report.paymentMethods.isNotEmpty)
          ReportPaymentsCard(methods: report.paymentMethods),
        if (report.topProducts.isNotEmpty)
          ReportRankedCard(
            title: tr.rpTopProducts,
            rows: [
              for (final p in report.topProducts)
                ReportRankedRow(
                  name: p.name,
                  quantity: p.quantitySold,
                  amount: p.grossAmount,
                ),
            ],
          ),
        if (report.topCategories.isNotEmpty)
          ReportRankedCard(
            title: tr.rpTopCategories,
            rows: [
              for (final c in report.topCategories)
                ReportRankedRow(
                  name: c.name,
                  quantity: c.quantitySold,
                  amount: c.grossAmount,
                ),
            ],
          ),
        if (days > 1 && hasHours) ReportPeakHoursCard(hours: report.peakHours),
        if (days >= 7 && hasDays) ReportDayOfWeekCard(days: report.dayOfWeek),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            tr.rpUpdated(time),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textHint),
          ),
        ),
      ],
    );
  }
}
