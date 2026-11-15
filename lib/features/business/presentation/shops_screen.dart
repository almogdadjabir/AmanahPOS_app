import 'package:amana_pos/common/auth_bloc/auth_bloc.dart' hide BusinessStatus;
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_form_parts.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_helpers.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shops of the business: list with swipe deactivate / reactivate.
class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final fallback = context.select<AuthBloc, BusinessData?>(
      (b) => b.state.defaultBusiness,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BusinessBloc, BusinessState>(
          builder: (context, state) {
            final business = currentBusiness(state, fallback);
            final shops = business?.shops ?? const <ShopData>[];
            final loading =
                business == null &&
                (state.businessStatus == BusinessStatus.initial ||
                    state.businessStatus == BusinessStatus.loading);

            return Column(
              children: [
                BizNavBar(
                  backLabel: tr.back,
                  trailing: business?.id == null
                      ? null
                      : Pressable(
                          onTap: () =>
                              openShopForm(context, businessId: business!.id!),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              PhosphorIconsRegular.plus,
                              size: 26,
                              color: colors.primary,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      AppLargeTitle(title: tr.shpTitle),
                      if (loading)
                        const ShopsSkeleton()
                      else if (shops.isEmpty)
                        BizEmptyCard(
                          icon: PhosphorIconsRegular.storefront,
                          title: tr.shpEmptyTitle,
                          body: tr.shpEmptyBody,
                          actionLabel: tr.shAdd,
                          onAction: () {
                            final id = business?.id;
                            if (id == null) return;
                            openShopForm(context, businessId: id);
                          },
                        )
                      else ...[
                        _ShopList(businessId: business!.id!, shops: shops),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            20,
                            8,
                            20,
                            0,
                          ),
                          child: Text(
                            tr.shSwipeHint,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                      ],
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

class _ShopList extends StatelessWidget {
  final String businessId;
  final List<ShopData> shops;

  const _ShopList({required this.businessId, required this.shops});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < shops.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 44 + AppDims.s3,
                  color: colors.border,
                ),
              AppSwipeActions(
                actions: [
                  shops[i].isActive == false
                      ? AppSwipeAction(
                          label: tr.shSwipeReactivate,
                          icon: PhosphorIconsRegular.arrowUUpLeft,
                          color: colors.primary,
                          onTap: () => setShopActive(
                            context,
                            businessId: businessId,
                            shop: shops[i],
                            active: true,
                          ),
                        )
                      : AppSwipeAction(
                          label: tr.shSwipeDeactivate,
                          icon: PhosphorIconsRegular.prohibit,
                          color: colors.danger,
                          onTap: () => setShopActive(
                            context,
                            businessId: businessId,
                            shop: shops[i],
                            active: false,
                          ),
                        ),
                ],
                child: _ShopRow(
                  key: ValueKey(shops[i].id ?? i),
                  shop: shops[i],
                  onTap: () => openShopForm(
                    context,
                    businessId: businessId,
                    shop: shops[i],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  final ShopData shop;
  final VoidCallback onTap;

  const _ShopRow({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;
    final isActive = shop.isActive != false;
    final name = shop.name?.trim();
    final address = shop.address?.trim();

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primaryContainer
                        : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.storefront,
                    size: 22,
                    color: isActive ? colors.primary : colors.disabled,
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name?.isNotEmpty == true ? name! : tr.shop,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge!.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  tr.shInactive,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (address?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(
                              fontSize: 13,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
