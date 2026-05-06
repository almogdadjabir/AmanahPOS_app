import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_action_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductStockCard extends StatelessWidget {
  final StockData stock;

  const ProductStockCard({super.key,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isOut = stock.isOutOfStock ?? false;
    final isLow = stock.isLowStock ?? false;

    final color = isOut
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final label = isOut
        ? 'Out of stock'
        : isLow
        ? 'Low stock'
        : 'In stock';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          final allStock = context.read<InventoryBloc>().state.stockList;

          showStockActionSheet(
            context,
            stock: stock,
            allStock: allStock,
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.shopName ?? 'Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatQty(stock.qty),
                style: AppTextStyles.bs600(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                Icons.tune_rounded,
                color: colors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}