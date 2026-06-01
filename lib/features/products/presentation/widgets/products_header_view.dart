import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

enum ProductQuickFilter {
  all,
  active,
  outOfStock,
}

class ProductsHeaderView extends StatelessWidget {
  final List<ProductData> products;
  final int categoryCount;
  final ProductQuickFilter selectedQuickFilter;
  final ValueChanged<ProductQuickFilter> onQuickFilterChanged;

  const ProductsHeaderView({
    super.key,
    required this.products,
    required this.categoryCount,
    required this.selectedQuickFilter,
    required this.onQuickFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state.permissions.isRestaurant,
      builder: (context, isRestaurant) {
        final stats = _ProductHeaderStats.fromProducts(products);

        return _ProductsHeaderContent(
          isRestaurant: isRestaurant,
          totalCount: products.length,
          activeCount: stats.activeCount,
          outOfStockCount: stats.outOfStockCount,
          selectedQuickFilter: selectedQuickFilter,
          onQuickFilterChanged: onQuickFilterChanged,
        );
      },
    );
  }
}

class _ProductsHeaderContent extends StatelessWidget {
  final bool isRestaurant;
  final int totalCount;
  final int activeCount;
  final int outOfStockCount;
  final ProductQuickFilter selectedQuickFilter;
  final ValueChanged<ProductQuickFilter> onQuickFilterChanged;

  const _ProductsHeaderContent({
    required this.isRestaurant,
    required this.totalCount,
    required this.activeCount,
    required this.outOfStockCount,
    required this.selectedQuickFilter,
    required this.onQuickFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final title = isRestaurant
        ? tr.menuCatalogTitle
        : tr.productCatalogTitle;

    final subtitle = isRestaurant
        ? tr.menuCatalogSubtitle
        : tr.productCatalogSubtitle;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Column(
          children: [
            Row(
              children: [
                _HeaderIcon(isRestaurant: isRestaurant),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: _HeaderText(
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s4),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: tr.productStatAll,
                    value: totalCount.toString(),
                    icon: isRestaurant
                        ? SolarIconsOutline.chefHat
                        : SolarIconsOutline.bag5,
                    color: colors.primary,
                    isSelected:
                    selectedQuickFilter == ProductQuickFilter.all,
                    onTap: () {
                      onQuickFilterChanged(ProductQuickFilter.all);
                    },
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _MiniStat(
                    label: tr.productStatActive,
                    value: activeCount.toString(),
                    icon: SolarIconsOutline.checkCircle,
                    color: const Color(0xFF16A34A),
                    isSelected:
                    selectedQuickFilter == ProductQuickFilter.active,
                    onTap: () {
                      onQuickFilterChanged(ProductQuickFilter.active);
                    },
                  ),
                ),
                if (!isRestaurant) ...[
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: _MiniStat(
                      label: tr.productStatOutOfStock,
                      value: outOfStockCount.toString(),
                      icon: SolarIconsOutline.bagCross,
                      color: const Color(0xFFDC2626),
                      isSelected: selectedQuickFilter ==
                          ProductQuickFilter.outOfStock,
                      onTap: () {
                        onQuickFilterChanged(
                          ProductQuickFilter.outOfStock,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final bool isRestaurant;

  const _HeaderIcon({
    required this.isRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(
        isRestaurant ? SolarIconsOutline.chefHat : SolarIconsOutline.bag5,
        color: colors.primary,
        size: 30,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderText({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs700(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs300(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s2,
            vertical: AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              width: isSelected ? 1.4 : 1,
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs100(context).copyWith(
                  color: isSelected ? color : colors.textSecondary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductHeaderStats {
  final int activeCount;
  final int outOfStockCount;

  const _ProductHeaderStats({
    required this.activeCount,
    required this.outOfStockCount,
  });

  factory _ProductHeaderStats.fromProducts(List<ProductData> products) {
    var activeCount = 0;
    var outOfStockCount = 0;

    for (final product in products) {
      if (product.isActive == true) {
        activeCount++;
      }

      if ((product.stockLevel ?? 0) <= 0) {
        outOfStockCount++;
      }
    }

    return _ProductHeaderStats(
      activeCount: activeCount,
      outOfStockCount: outOfStockCount,
    );
  }
}