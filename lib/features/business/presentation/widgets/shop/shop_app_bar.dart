import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/edit_shop_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ShopAppBar extends StatelessWidget {
  final String businessId;
  final ShopData shop;

  const ShopAppBar({
    super.key,
    required this.businessId,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: DirectionalIcon(
          icon: SolarIconsOutline.arrowLeft,
          color: colors.textPrimary,
          size: 22,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            showEditShopSheet(
              context,
              businessId: businessId,
              shop: shop,
            );
          },
          icon: Icon(
            SolarIconsOutline.pen,
            color: colors.textPrimary,
            size: 20,
          ),
          tooltip: context.tr.editShop,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  SolarIconsOutline.shop,
                  size: 30,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                child: Text(
                  shop.name?.trim().isNotEmpty == true
                      ? shop.name!.trim()
                      : context.tr.shop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}