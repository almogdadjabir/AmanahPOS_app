import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/business_overview_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_action_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_header.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SingleBusinessWorkspace extends StatelessWidget {
  final BusinessData data;

  const SingleBusinessWorkspace({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = data.isActive ?? false;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s4, AppDims.s4, AppDims.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: WorkspaceHeader(data: data, isActive: isActive)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s2, AppDims.s4, 0,
            ),
            sliver: SliverToBoxAdapter(
              child: BusinessOverviewCard(data: data)
                  .animate()
                  .fadeIn(delay: 90.ms, duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s4, AppDims.s4, 0,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Workspace',
                style: AppTextStyles.bs600(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s6,
            ),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate.fixed([
                WorkspaceActionCard(
                  icon: Icons.store_mall_directory_rounded,
                  title: 'Shops',
                  subtitle: 'Manage locations',
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteStrings.shopManagementScreen,
                    arguments: {'businessData': data},
                  ),
                ),
                WorkspaceActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'Products',
                  subtitle: 'Catalog & stock',
                  onTap: () => Navigator.of(context).pushNamed(RouteStrings.productScreen),
                ),
                WorkspaceActionCard(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Cashiers',
                  subtitle: 'Team access',
                  onTap: () {},
                ),
                WorkspaceActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  subtitle: 'Sales insights',
                  onTap: () {},
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppDims.s3,
                crossAxisSpacing: AppDims.s3,
                childAspectRatio: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}