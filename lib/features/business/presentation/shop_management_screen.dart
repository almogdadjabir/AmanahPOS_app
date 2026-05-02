import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/add_shop_sheet.dart';
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
                    child: IconButton(
                      onPressed: () => showAddShopSheet(context, data.id),
                      icon: Icon(
                        Icons.add_business_rounded,
                        color: context.appColors.primary,
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
                  child: _ShopManagementHeader(
                    business: data,
                    shops: shops,
                  )
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _QuickStats(shops: shops)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s5,
                  AppDims.s4,
                  AppDims.s2,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Shops',
                          style: AppTextStyles.bs600(context).copyWith(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton.icon(
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
                    ],
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
                    0,
                    AppDims.s4,
                    AppDims.s6,
                  ),
                  sliver: SliverList.separated(
                    itemCount: shops.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDims.s3),
                    itemBuilder: (context, index) {
                      return _ShopManagementCard(
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

class _ShopManagementHeader extends StatelessWidget {
  final BusinessData business;
  final List<Shops> shops;

  const _ShopManagementHeader({
    required this.business,
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name ?? 'Business',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shops.isEmpty
                      ? 'Create your first shop to start selling.'
                      : 'Manage all shop locations under this business.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final List<Shops> shops;

  const _QuickStats({
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = shops.where((shop) => shop.isActive == true).length;
    final inactiveCount = shops.length - activeCount;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.store_mall_directory_outlined,
            label: 'Total Shops',
            value: '${shops.length}',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Active',
            value: '$activeCount',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: Icons.pause_circle_outline_rounded,
            label: 'Inactive',
            value: '$inactiveCount',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: colors.primary,
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            value,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopManagementCard extends StatelessWidget {
  final Shops shop;
  final String? businessId;

  const _ShopManagementCard({
    required this.shop,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = shop.isActive ?? false;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDims.rLg),
        onTap: () {
          if (businessId == null) return;

          Navigator.of(context).pushNamed(
            RouteStrings.shopDetailScreen,
            arguments: {
              'businessId': businessId,
              'shop': shop,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: colors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name ?? 'Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (shop.address?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.address!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs200(context).copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDims.s2),
                    _ShopStatusBadge(active: isActive),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s2),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopStatusBadge extends StatelessWidget {
  final bool active;

  const _ShopStatusBadge({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          color: active ? const Color(0xFF16A34A) : colors.textHint,
          fontWeight: FontWeight.w900,
        ),
      ),
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