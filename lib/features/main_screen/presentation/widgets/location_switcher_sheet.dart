import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class LocationSwitcherSheet extends StatelessWidget {
  const LocationSwitcherSheet({
    super.key,
    required this.business,
    required this.selectedShopId,
  });

  final BusinessData business;
  final String? selectedShopId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final shops = business.shops
        ?.where((shop) => shop.id != null && (shop.isActive ?? true))
        .toList() ??
        [];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s5,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: AppDims.s4),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    SolarIconsOutline.shop,
                    color: colors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch location',
                        style: AppTextStyles.bs500(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        business.name ?? 'Workspace',
                        style: AppTextStyles.bs100(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDims.s2),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  final isSelected = shop.id == selectedShopId;

                  return _ShopTile(
                    name: shop.name ?? 'Shop',
                    isSelected: isSelected,
                    onTap: () {
                      final shopId = shop.id;
                      if (shopId == null || shopId.isEmpty) return;

                      context.read<PosBloc>().add(
                        PosShopSelected(
                          shopId: shopId,
                          shopName: shop.name ?? 'Shop',
                        ),
                      );

                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: isSelected ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.10)
              : colors.surfaceSoft.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.45)
                : colors.border.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? SolarIconsBold.checkCircle
                  : SolarIconsOutline.mapPoint,
              size: 21,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bs300(context).copyWith(
                  color: isSelected ? colors.primary : colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}