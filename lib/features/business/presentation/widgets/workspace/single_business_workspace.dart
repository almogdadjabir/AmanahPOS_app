import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_header.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_manage_group.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_payments_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_plan_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_states.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_today_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_top_sellers.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the Home summary area shows for a dashboard state.
enum HomeSummaryView {
  /// REST load with nothing cached yet.
  skeleton,

  /// Before the first value arrives (local data comes from SQLite within
  /// milliseconds): show nothing rather than flashing "no sales yet".
  awaitingFirstValue,

  /// A real day without sales (or a failed load with nothing to show).
  empty,
  data,
}

HomeSummaryView homeSummaryViewOf(DashboardSummaryState state) {
  final summary = state.summary;
  if (summary == null) {
    if (state.isLoading) return HomeSummaryView.skeleton;
    if (state.status == DashboardSummaryStatus.initial) {
      return HomeSummaryView.awaitingFirstValue;
    }
    return HomeSummaryView.empty;
  }
  if (summary.today.salesCount == 0 && summary.today.grossSalesAmount == 0) {
    return HomeSummaryView.empty;
  }
  return HomeSummaryView.data;
}

/// Owner Home tab: today's numbers, payments, top sellers, manage, plan.
class SingleBusinessWorkspace extends StatelessWidget {
  final BusinessData data;

  const SingleBusinessWorkspace({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // The tab bar floats over the body (extendBody), so SafeArea would also
    // reserve the cart-peek space and leave a blank band. Pad the scroll
    // instead: content fills the screen and scrolls under the bar.
    final bottomInset =
        NavShell.contentHeight + MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.summary != curr.summary,
        builder: (context, state) {
          final summary = state.summary;
          final view = homeSummaryViewOf(state);
          final loading = view == HomeSummaryView.skeleton;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  HapticFeedback.selectionClick();
                  final bloc = context.read<DashboardSummaryBloc>()
                    ..add(const OnDashboardSummaryRefreshRequested());
                  await bloc.stream
                      .firstWhere((s) => !s.isLoading && !s.isRefreshing)
                      .timeout(
                        const Duration(seconds: 10),
                        onTimeout: () => bloc.state,
                      );
                },
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    HomeHeader(summary: summary, loading: loading),
                    switch (view) {
                      HomeSummaryView.skeleton => const HomeSkeleton(),
                      HomeSummaryView.awaitingFirstValue =>
                        const SizedBox.shrink(),
                      HomeSummaryView.empty => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeTodayCard(summary: summary),
                          const HomeEmptyCard(),
                        ],
                      ),
                      HomeSummaryView.data => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeTodayCard(summary: summary),
                          HomePaymentsCard(today: summary!.today),
                          HomeTopSellers(sellers: summary.topSellers),
                        ],
                      ),
                    },
                    HomeManageGroup(data: data),
                    HomePlanCard(data: data),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
