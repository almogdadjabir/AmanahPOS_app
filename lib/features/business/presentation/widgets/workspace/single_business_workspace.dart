import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/subscription_plan_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_action_card.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SingleBusinessWorkspace extends StatelessWidget {
  final BusinessData data;

  const SingleBusinessWorkspace({
    super.key,
    required this.data,
  });

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
                    dateLabel: _dashboardDateLabel(summary.today.date),
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
              child: WorkspaceSectionHeader(title: 'MANAGE'),
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
                crossAxisCount: 2,
                shrinkWrap: true,
                clipBehavior: Clip.none,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDims.s3,
                crossAxisSpacing: AppDims.s3,
                childAspectRatio: 2.38,
                children: [
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.shop),
                    title: 'Shops',
                    value: shopCount.toString(),
                    subtitle: shopCount == 1 ? 'Active branch' : 'Active branches',
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteStrings.shopManagementScreen,
                      arguments: {'businessData': data},
                    ),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.box),
                    title: 'Products',
                    value: productCount.toString(),
                    subtitle: productCount == 1 ? 'Products item' : 'Products items',
                    onTap: () {
                      Navigator.of(context).pushNamed(RouteStrings.productScreen);
                    },
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.usersGroupRounded),
                    title: 'Cashiers',
                    value: cashierCount.toString(),
                    subtitle: cashierCount == 1 ? 'User' : 'Users',
                    onTap: () {
                      Navigator.of(context).pushNamed(RouteStrings.cashiersScreen);
                    },
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.notebook),
                    title: 'Reports',
                    subtitle: 'Browse and search all transactions',
                    onTap: () => Navigator.of(context).pushNamed(RouteStrings.salesHistoryScreen),
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


  String _dashboardDateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return 'TODAY';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return 'TODAY · ${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }
}