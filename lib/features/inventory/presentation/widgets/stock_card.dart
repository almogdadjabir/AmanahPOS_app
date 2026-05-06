import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_action_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockCard extends StatelessWidget {
  final StockData item;

  const StockCard({super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isOut = item.isOutOfStock ?? false;
    final isLow = item.isLowStock ?? false;
    final qty = item.qty;

    final statusColor = isOut
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final statusLabel = isOut
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
            stock: item,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  isOut
                      ? Icons.remove_shopping_cart_outlined
                      : isLow
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  size: 25,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: colors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.shopName ?? 'Shop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs200(context).copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.productSku?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        'SKU: ${item.productSku!.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs100(context).copyWith(
                          color: colors.textHint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDims.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.bs100(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatQty(qty),
                    style: AppTextStyles.bs600(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Qty',
                    style: AppTextStyles.bs100(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textHint,
                    ),
                  ),
                  const SizedBox(height: AppDims.s3),
                  Icon(
                    Icons.tune_rounded,
                    color: colors.textHint,
                    size: 18,
                  ),
                ],
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
