import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

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
    final stock  = product.stockLevel ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color:        colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border:       Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset:     const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Row 1: Price + Category ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon:  Icons.payments_outlined,
                  label: 'Price',
                  value: _formatPrice(product.price),
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InfoTile(
                  icon:  Icons.layers_outlined,
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

          // ── Row 2: Stock + Status  OR  Status full-width ───────────────
          if (showStock)
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon:  Icons.inventory_2_outlined,
                    label: 'Stock',
                    value: _formatQty(stock),
                    color: _stockColor(stock),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(child: _statusTile(context)),
              ],
            )
          else
            _statusTile(context),

          // ── Stock chip (shops only) ────────────────────────────────────
          if (showStock) ...[
            const SizedBox(height: AppDims.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: StockChip(level: stock),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusTile(BuildContext context) {
    final isActive = product.isActive != false;
    return _InfoTile(
      icon:  isActive
          ? Icons.check_circle_outline_rounded
          : Icons.pause_circle_outline_rounded,
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
  final String   label;
  final String   value;
  final Color    color;

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
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color:      colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color:      colors.textHint,
                    fontWeight: FontWeight.w700,
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