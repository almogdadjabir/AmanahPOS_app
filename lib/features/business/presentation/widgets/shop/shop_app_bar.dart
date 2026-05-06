import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/edit_shop_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ShopAppBar extends StatelessWidget {
  final String businessId;
  final Shops shop;
  const ShopAppBar({super.key, required this.businessId, required this.shop});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: context.appColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded,
            color: context.appColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              showEditShopSheet(context, businessId: businessId, shop: shop),
          icon: Icon(Icons.edit_outlined,
              color: context.appColors.textPrimary, size: 20),
          tooltip: 'Edit shop',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.appColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(Icons.storefront_outlined,
                    size: 30, color: context.appColors.primary),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                shop.name ?? '—',
                style: AppTextStyles.bs600(context).copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
