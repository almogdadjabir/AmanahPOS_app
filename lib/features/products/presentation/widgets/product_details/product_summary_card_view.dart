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
    final stock = product.stockLevel ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: SolarIconsOutline.walletMoney,
                  label: 'Price',
                  value: _formatPrice(product.price),
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InfoTile(
                  icon: SolarIconsOutline.layersMinimalistic,
                  label: 'Category',
                  value: product.categoryName?.trim().isNotEmpty == true
                      ? product.categoryName!.trim()
                      : 'No category',
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
                    label: 'Stock',
                    value: _formatQty(stock),
                    color: _stockColor(stock),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _statusTile(context),
                ),
              ],
            )
          else
            _statusTile(context),

          if (showStock) _buildAlertRow(context),
        ],
      ),
    );
  }

  Widget _buildAlertRow(BuildContext context) {
    final minStock = product.minStockLevel;
    final expiryDays = product.expiryAlertDays;

    final hasMin = minStock != null;
    final hasExpiry = expiryDays != null;

    if (!hasMin && !hasExpiry) {
      return const SizedBox.shrink();
    }

    const amber = Color(0xFFF59E0B);
    const orange = Color(0xFFEA580C);

    final minTile = hasMin
        ? _InfoTile(
      icon: SolarIconsOutline.dangerTriangle,
      label: 'Min Stock',
      value: _formatQty(minStock),
      color: amber,
    )
        : null;

    final expiryTile = hasExpiry
        ? _InfoTile(
      icon: SolarIconsOutline.calendarMark,
      label: 'Expiry Alert',
      value: '$expiryDays day${expiryDays == 1 ? '' : 's'}',
      color: orange,
    )
        : null;

    if (minTile != null && expiryTile == null) {
      return Column(
        children: [
          const SizedBox(height: AppDims.s2),
          minTile,
        ],
      );
    }

    if (expiryTile != null && minTile == null) {
      return Column(
        children: [
          const SizedBox(height: AppDims.s2),
          expiryTile,
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppDims.s2),
        Row(
          children: [
            Expanded(child: minTile!),
            const SizedBox(width: AppDims.s2),
            Expanded(child: expiryTile!),
          ],
        ),
      ],
    );
  }

  Widget _statusTile(BuildContext context) {
    final isActive = product.isActive != false;

    return _InfoTile(
      icon: isActive
          ? SolarIconsOutline.checkCircle
          : SolarIconsOutline.pauseCircle,
      label: 'Status',
      value: isActive ? 'Active' : 'Inactive',
      color: isActive ? const Color(0xFF16A34A) : context.appColors.textHint,
    );
  }

  Color _stockColor(double value) {
    if (value <= 0) return const Color(0xFFDC2626);
    if (value <= 5) return const Color(0xFFEA580C);
    return const Color(0xFF16A34A);
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00';
    return '$value';
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
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

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rSm),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
    );
  }
}