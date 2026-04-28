import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/add_shop_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';


class ShopsSection extends StatelessWidget {
  final List<Shops> shops;
  final String? businessId;
  const ShopsSection({super.key, required this.shops, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SHOPS',
              style: AppTextStyles.bs200(context).copyWith(
              fontWeight: FontWeight.w800,
                color: context.appColors.textHint,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => showAddShopSheet(context, businessId),
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Shop',
                style: AppTextStyles.bs400(context).copyWith(
                fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s2),

        if (shops.isEmpty)
          _EmptyShops()
        else
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Column(
              children: [
                for (var i = 0; i < shops.length; i++) ...[
                  _ShopTile(shop: shops[i], businessId: businessId!),
                  if (i < shops.length - 1) Divider(
                    height: 1, thickness: 1,
                    indent: AppDims.s4,
                    color: context.appColors.border,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ShopTile extends StatelessWidget {
  final Shops shop;
  final String businessId;
  const _ShopTile({required this.shop, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final isActive = shop.isActive ?? false;

    return InkWell(
      onTap: ()=> Navigator.of(context).pushNamed(
        RouteStrings.shopDetailScreen,
        arguments: {'businessId': businessId, 'shop': shop},
      ),
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4, vertical: AppDims.s3),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rSm),
              ),
              child: Icon(Icons.storefront_outlined,
                  size: 20, color: context.appColors.textSecondary),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name ?? '—',
                    style: AppTextStyles.bs400(context).copyWith(
                    fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  if (shop.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      shop.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                      fontWeight: FontWeight.w600,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF22C55E).withOpacity(0.12)
                    : context.appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w800,
                  color: isActive
                      ? const Color(0xFF16A34A)
                      : context.appColors.textHint,
                ),
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Icon(Icons.chevron_right_rounded,
                color: context.appColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _EmptyShops extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined,
              size: 32, color: context.appColors.textHint),
          const SizedBox(height: AppDims.s2),
          Text(
            'No shops yet',
            style: AppTextStyles.bs400(context).copyWith(
            fontWeight: FontWeight.w700,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}