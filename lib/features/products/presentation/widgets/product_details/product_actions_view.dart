
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/delete_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/edit_product_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductActionsView extends StatelessWidget {
  final ProductData product;
  final bool        showStock;

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
        // Edit — always visible
        Expanded(
          child: _ActionButton(
            icon:  Icons.edit_outlined,
            label: 'Edit',
            color: colors.primary,
            onTap: () => showEditProductSheet(context, product: product),
          ),
        ),

        // Add Stock — shops only
        if (showStock) ...[
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: _ActionButton(
              icon:  Icons.inventory_2_outlined,
              label: 'Add Stock',
              color: const Color(0xFF16A34A),
              onTap: () => showAddStockProductSheet(
                context,
                initialProduct: product,
              ),
            ),
          ),
        ],

        // Delete — always visible
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _ActionButton(
            icon:  Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFDC2626),
            onTap: () => showDeleteProductSheet(context, product: product),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color:        colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          height:  72,
          padding: const EdgeInsets.all(AppDims.s2),
          decoration: BoxDecoration(
            border:       Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color:      colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}