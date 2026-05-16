import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class RestockQueueCard extends StatelessWidget {
  final List<StockData> lowStockItems;
  final bool isLoading;
  final VoidCallback? onTap;

  const RestockQueueCard({
    super.key,
    required this.lowStockItems,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final top3 = lowStockItems.take(3).toList();

    return BentoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: CardHeader(
                  title: 'Restock Queue',
                  icon: SolarIconsOutline.boxMinimalistic,
                  accent: Color(0xFFFCD34D),
                ),
              ),
              if (lowStockItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s2, vertical: AppDims.s1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDims.rXl),
                  ),
                  child: Text(
                    '${lowStockItems.length} items',
                    style: const TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDims.s3),
          if (isLoading) ...[
            const ShimmerBox(height: 40),
            const SizedBox(height: AppDims.s2),
            const ShimmerBox(height: 40),
          ] else if (top3.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDims.s3),
                child: Text(
                  'All stock levels healthy',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...top3.map((item) => _RestockRow(item: item)),
        ],
      ),
    );
  }
}

class _RestockRow extends StatelessWidget {
  final StockData item;
  const _RestockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOut = item.isOutOfStock ?? false;
    final badgeColor =
        isOut ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D);
    final badgeText = isOut ? 'Out' : 'Low';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDims.s2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s2, vertical: AppDims.s1),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDims.rSm),
              border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              item.productName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            item.quantity ?? '0',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
