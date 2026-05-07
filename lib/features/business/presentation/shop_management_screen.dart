import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/add_shop_sheet.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/shop_management_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/shop_quick_stats.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopManagementScreen extends StatelessWidget {
  final BusinessData business;

  const ShopManagementScreen({
    super.key,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BusinessBloc, BusinessState, BusinessData?>(
      selector: (state) {
        return state.businessList?.firstWhere(
              (b) => b.id == business.id,
          orElse: () => business,
        );
      },
      builder: (context, currentBusiness) {
        final data = currentBusiness ?? business;
        final shops = data.shops ?? const <Shops>[];

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: context.appColors.surface,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: context.appColors.textPrimary,
                  ),
                ),
                title: Text(
                  'Shop Management',
                  style: AppTextStyles.bs500(context).copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppDims.s2),
                    child: TextButton.icon(
                      onPressed: () => showAddShopSheet(context, data.id),
                      style: TextButton.styleFrom(
                        foregroundColor: context.appColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 34),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(
                        'Add Shop',
                        style: AppTextStyles.bs300(context).copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ShopQuickStats(shops: shops)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),


              if (shops.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s2,
                    AppDims.s4,
                    AppDims.s6,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyShopManagement(
                      onAddTap: () => showAddShopSheet(context, data.id),
                    )
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 320.ms)
                        .slideY(
                      begin: 0.06,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s4,
                    AppDims.s4,
                    AppDims.s6,
                  ),
                  sliver: SliverList.separated(
                    itemCount: shops.length,
                    separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDims.s3),
                    itemBuilder: (context, index) {
                      return ShopManagementCard(
                        shop: shops[index],
                        businessId: data.id,
                      )
                          .animate()
                          .fadeIn(
                        delay: Duration(milliseconds: 80 + (index * 40)),
                        duration: 280.ms,
                      )
                          .slideY(
                        begin: 0.05,
                        end: 0,
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


class _EmptyShopManagement extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyShopManagement({
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 34,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            'No shops yet',
            style: AppTextStyles.bs600(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            'Add your first shop location to start managing products, sales, and cashiers.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Add First Shop'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                textStyle: AppTextStyles.bs500(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}