import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/subscription_plan_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_action_card.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class SingleBusinessWorkspace extends StatelessWidget {
  final BusinessData data;

  const SingleBusinessWorkspace({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _DesktopWorkspace(data: data);
    }
    return _MobileWorkspace(data: data);
  }
}


class _DesktopWorkspace extends StatelessWidget {
  final BusinessData data;
  const _DesktopWorkspace({required this.data});

  @override
  Widget build(BuildContext context) {
    final shopCount = data.shopCount ?? 0;
    final productCount = context.read<ProductBloc>().state.products.length;
    final cashierCount = context.read<UserBloc>().state.userList.length;

    return SafeArea(
      child: CustomScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top row: today card + subscription card side-by-side ──────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, AppDims.s3, 0, 0),
            sliver: SliverToBoxAdapter(
              child: BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status || prev.summary != curr.summary,
                builder: (context, state) {
                  final summary = state.summary;

                  final todayCard = summary == null
                      ? OwnerTodayCard(
                          amount: 0,
                          salesCount: 0,
                          sparkline: const [0, 0],
                          liveLabel: state.isLoading ? '…' : 'NO DATA',
                        )
                      : OwnerTodayCard(
                          amount: summary.today.grossSalesAmount,
                          salesCount: summary.today.salesCount,
                          sparkline: summary.sparklineAmounts.isEmpty
                              ? const [0, 0]
                              : summary.sparklineAmounts,
                          dateLabel:
                              _dashboardDateLabel(context, summary.today.date),
                          liveLabel: summary.liveLabel,
                          currencyLabel: summary.currency,
                        );

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: todayCard
                              .animate()
                              .fadeIn(duration: 350.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                        const SizedBox(width: AppDims.s4),
                        Expanded(
                          flex: 2,
                          child: SubscriptionPlanCard(data: data),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Section header ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, AppDims.s5, 0, 0),
            sliver: SliverToBoxAdapter(
              child: WorkspaceSectionHeader(title: context.tr.bizManageLabel),
            ),
          ),

          // ── 4-column action grid ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, AppDims.s3, 0, AppDims.s6),
            sliver: SliverToBoxAdapter(
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                clipBehavior: Clip.none,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDims.s3,
                crossAxisSpacing: AppDims.s3,
                childAspectRatio: 0.92,
                children: [
                  WorkspaceActionCard(
                    vertical: true,
                    icon: const Icon(SolarIconsOutline.shop),
                    title: context.tr.bizShopsTitle,
                    value: shopCount.toString(),
                    subtitle: shopCount == 1
                        ? context.tr.bizActiveBranch
                        : context.tr.bizActiveBranches,
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteStrings.shopManagementScreen,
                      arguments: {'businessData': data},
                    ),
                  ),
                  WorkspaceActionCard(
                    vertical: true,
                    icon: const Icon(SolarIconsOutline.box),
                    title: context.tr.productsManagement,
                    value: productCount.toString(),
                    subtitle: productCount == 1
                        ? context.tr.bizProductsItem
                        : context.tr.bizProductsItems,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteStrings.productScreen),
                  ),
                  WorkspaceActionCard(
                    vertical: true,
                    icon: const Icon(SolarIconsOutline.usersGroupRounded),
                    title: context.tr.settingsCashiers,
                    value: cashierCount.toString(),
                    subtitle: cashierCount == 1
                        ? context.tr.bizUserSingular
                        : context.tr.bizUserPlural,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteStrings.cashiersScreen),
                  ),
                  WorkspaceActionCard(
                    vertical: true,
                    icon: const Icon(SolarIconsOutline.notebook),
                    title: context.tr.navReports,
                    subtitle: context.tr.bizReportSubtitle,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteStrings.salesHistoryScreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _MobileWorkspace extends StatelessWidget {
  final BusinessData data;
  const _MobileWorkspace({required this.data});

  @override
  Widget build(BuildContext context) {
    final shopCount = data.shopCount ?? 0;
    final productCount = context.read<ProductBloc>().state.products.length;
    final cashierCount = context.read<UserBloc>().state.userList.length;

    return SafeArea(
      child: CustomScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s2,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status || prev.summary != curr.summary,
                builder: (context, state) {
                  final summary = state.summary;

                  if (state.isLoading && summary == null) {
                    return const SizedBox(
                      height: 170,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (summary == null) {
                    return OwnerTodayCard(
                      amount: 0,
                      salesCount: 0,
                      sparkline: const [0, 0],
                      liveLabel: 'NO DATA',
                    );
                  }

                  return OwnerTodayCard(
                    amount: summary.today.grossSalesAmount,
                    salesCount: summary.today.salesCount,
                    sparkline: summary.sparklineAmounts.isEmpty
                        ? const [0, 0]
                        : summary.sparklineAmounts,
                    dateLabel:
                        _dashboardDateLabel(context, summary.today.date),
                    liveLabel: summary.liveLabel,
                    currencyLabel: summary.currency,
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(
                begin: 0.08,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s5,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: WorkspaceSectionHeader(title: context.tr.bizManageLabel),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s3,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: GridView.count(
                crossAxisCount: context.isTablet ? 4 : 2,
                shrinkWrap: true,
                clipBehavior: Clip.none,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDims.s3,
                crossAxisSpacing: AppDims.s3,
                childAspectRatio: context.isTablet ? 1.8 : 2.38,
                children: [
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.shop),
                    title: context.tr.bizShopsTitle,
                    value: shopCount.toString(),
                    subtitle: shopCount == 1
                        ? context.tr.bizActiveBranch
                        : context.tr.bizActiveBranches,
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteStrings.shopManagementScreen,
                      arguments: {'businessData': data},
                    ),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.box),
                    title: context.tr.productsManagement,
                    value: productCount.toString(),
                    subtitle: productCount == 1
                        ? context.tr.bizProductsItem
                        : context.tr.bizProductsItems,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteStrings.productScreen),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.usersGroupRounded),
                    title: context.tr.settingsCashiers,
                    value: cashierCount.toString(),
                    subtitle: cashierCount == 1
                        ? context.tr.bizUserSingular
                        : context.tr.bizUserPlural,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteStrings.cashiersScreen),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.notebook),
                    title: context.tr.navReports,
                    subtitle: context.tr.bizReportSubtitle,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteStrings.salesHistoryScreen),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s5,
              AppDims.s4,
              AppDims.s6,
            ),
            sliver: SliverToBoxAdapter(
              child: SubscriptionPlanCard(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

String _dashboardDateLabel(BuildContext context, String value) {
  final parsed = DateTime.tryParse(value);
  final todayLabel = context.tr.today;
  if (parsed == null) return todayLabel;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formattedDate = DateFormat('dd MMM yyyy', locale).format(parsed);
  return '$todayLabel · $formattedDate';
}
