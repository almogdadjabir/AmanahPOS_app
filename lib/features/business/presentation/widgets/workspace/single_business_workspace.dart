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
          final loading = state.isLoading && summary == null;
          final isEmpty =
              summary == null ||
              (summary.today.salesCount == 0 &&
                  summary.today.grossSalesAmount == 0);

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
                    if (loading)
                      const HomeSkeleton()
                    else ...[
                      HomeTodayCard(summary: summary),
                      if (isEmpty)
                        const HomeEmptyCard()
                      else ...[
                        HomePaymentsCard(today: summary.today),
                        HomeTopSellers(sellers: summary.topSellers),
                      ],
                    ],
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
