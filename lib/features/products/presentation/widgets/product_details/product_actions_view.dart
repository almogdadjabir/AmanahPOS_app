import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/delete_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/edit_product_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductActionsView extends StatelessWidget {
  final ProductData product;
  final bool showStock;

  const ProductActionsView({
    super.key,
    required this.product,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: SolarIconsOutline.penNewSquare,
            label: 'Edit',
            color: colors.primary,
            onTap: () {
              showEditProductSheet(context, product: product);
            },
          ),
        ),

        if (showStock) ...[
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: _ActionButton(
              icon: SolarIconsOutline.box,
              label: 'Add Stock',
              color: const Color(0xFF16A34A),
              onTap: () {
                showAddStockProductSheet(
                  context,
                  initialProduct: product,
                );
              },
            ),
          ),
        ],

        const SizedBox(width: AppDims.s2),

        Expanded(
          child: _ActionButton(
            icon: SolarIconsOutline.trashBinTrash,
            label: 'Delete',
            color: const Color(0xFFDC2626),
            isDanger: true,
            onTap: () {
              showDeleteProductSheet(context, product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDanger;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s2,
            vertical: AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: isDanger
                ? color.withValues(alpha: 0.07)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: isDanger
                  ? color.withValues(alpha: 0.22)
                  : colors.border,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: isDanger ? color : colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
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