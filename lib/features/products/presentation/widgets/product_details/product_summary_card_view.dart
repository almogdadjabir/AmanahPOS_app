import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/localization/app_localizations_product_extensions.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductSummaryCardView extends StatelessWidget {
  final ProductData product;
  final bool showStock;

  const ProductSummaryCardView({
    super.key,
    required this.product,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final stock = product.stockLevel ?? 0;
    final categoryName = product.categoryName?.trim();
    final isActive = product.isActive != false;

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
                Expanded(
                  child: _InfoTile(
                    icon: SolarIconsOutline.walletMoney,
                    label: tr.price,
                    value: _formatPrice(product.price),
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _InfoTile(
                    icon: SolarIconsOutline.tag,
                    label: tr.category,
                    value: categoryName?.isNotEmpty == true
                        ? categoryName!
                        : tr.noCategory,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDims.s2),

            if (showStock)
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: SolarIconsOutline.box,
                      label: tr.stock,
                      value: _formatQty(stock),
                      color: _stockColor(stock),
                    ),
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: _StatusTile(isActive: isActive),
                  ),
                ],
              )
            else
              _StatusTile(isActive: isActive),

            if (showStock)
              _AlertRow(
                minStock: product.minStockLevel,
                expiryDays: product.expiryAlertDays,
              ),
          ],
        ),
      ),
    );
  }

  static Color _stockColor(double value) {
    if (value <= 0) return const Color(0xFFDC2626);
    if (value <= 5) return const Color(0xFFEA580C);
    return const Color(0xFF16A34A);
  }

  static String _formatPrice(dynamic value) {
    if (value == null) return '0.00';

    if (value is num) {
      return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    }

    return value.toString();
  }

  static String _formatQty(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _AlertRow extends StatelessWidget {
  final double? minStock;
  final int? expiryDays;

  const _AlertRow({
    required this.minStock,
    required this.expiryDays,
  });

  @override
  Widget build(BuildContext context) {
    final hasMinStock = minStock != null;
    final hasExpiryAlert = expiryDays != null;

    if (!hasMinStock && !hasExpiryAlert) {
      return const SizedBox.shrink();
    }

    const amber = Color(0xFFF59E0B);
    const orange = Color(0xFFEA580C);

    final minTile = hasMinStock
        ? _InfoTile(
      icon: SolarIconsOutline.dangerTriangle,
      label: context.tr.fieldMinStockLevel,
      value: ProductSummaryCardView._formatQty(minStock!),
      color: amber,
    )
        : null;

    final expiryTile = hasExpiryAlert
        ? _InfoTile(
      icon: SolarIconsOutline.calendarMark,
      label: context.tr.fieldExpiryAlert,
      value: context.tr.dayCountLabel(expiryDays!),
      color: orange,
    )
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: AppDims.s2),
      child: Row(
        children: [
          if (minTile != null) Expanded(child: minTile),
          if (minTile != null && expiryTile != null)
            const SizedBox(width: AppDims.s2),
          if (expiryTile != null) Expanded(child: expiryTile),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final bool isActive;

  const _StatusTile({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _InfoTile(
      icon: isActive
          ? SolarIconsOutline.checkCircle
          : SolarIconsOutline.pauseCircle,
      label: context.tr.status,
      value: isActive ? context.tr.active : context.tr.inactive,
      color: isActive ? const Color(0xFF16A34A) : colors.textHint,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s3),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rSm),
              ),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs400(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs100(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}