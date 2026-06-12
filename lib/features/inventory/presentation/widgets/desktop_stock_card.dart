import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_action_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Grid tile for the desktop inventory view. A taller, hover-aware sibling
/// of [StockCard] — adds an expiry indicator and a dedicated "Manage"
/// affordance suited to mouse interaction instead of a tap-anywhere row.
class DesktopStockCard extends StatefulWidget {
  final StockData item;

  const DesktopStockCard({super.key, required this.item});

  @override
  State<DesktopStockCard> createState() => _DesktopStockCardState();
}

class _DesktopStockCardState extends State<DesktopStockCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final item = widget.item;

    final isOut = item.isOutOfStock ?? false;
    final isLow = item.isLowStock ?? false;
    final qty = item.qty;
    final displayName = item.productName ?? 'Product';

    final statusColor = isOut
        ? colors.danger
        : isLow
        ? colors.stockLow
        : colors.success;

    final statusLabel = isOut
        ? 'Out of stock'
        : isLow
        ? 'Low stock'
        : 'In stock';

    final statusIcon = isOut
        ? SolarIconsOutline.cartCross
        : isLow
        ? SolarIconsOutline.dangerTriangle
        : SolarIconsOutline.boxMinimalistic;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDims.rXl),
          onTap: () {
            final allStock = context.read<InventoryBloc>().state.stockList;
            showStockActionSheet(context, stock: item, allStock: allStock);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(
                color: _hovered
                    ? statusColor.withValues(alpha: 0.40)
                    : colors.border,
                width: _hovered ? 1.3 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      child: Icon(statusIcon, size: 21, color: statusColor),
                    ),
                    const Spacer(),
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
                        style: AppTextStyles.sm100(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDims.s3),
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: displayName.contentDirection,
                  style: AppTextStyles.bs300(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      SolarIconsOutline.shop_2,
                      size: 13,
                      color: colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.shopName ?? 'Shop',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sm300(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
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
                    style: AppTextStyles.sm100(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                if (item.isExpiredSafe || item.isExpiringSoon) ...[
                  _ExpiryChip(item: item),
                  const SizedBox(height: AppDims.s3),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatQty(qty),
                          style: AppTextStyles.bs600(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'units in stock',
                          style: AppTextStyles.sm100(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _hovered
                            ? colors.primary.withValues(alpha: 0.12)
                            : colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                        border: Border.all(
                          color: _hovered
                              ? colors.primary.withValues(alpha: 0.30)
                              : colors.border,
                        ),
                      ),
                      child: Icon(
                        SolarIconsOutline.settings,
                        size: 17,
                        color: _hovered ? colors.primary : colors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

class _ExpiryChip extends StatelessWidget {
  final StockData item;

  const _ExpiryChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isExpired = item.isExpiredSafe;
    final color = isExpired ? colors.danger : colors.warning;
    final days = item.expiresInDays;

    final label = isExpired
        ? 'Expired'
        : days == null
        ? 'Expiring soon'
        : days <= 0
        ? 'Expires today'
        : days == 1
        ? 'Expires in 1 day'
        : 'Expires in $days days';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rSm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(SolarIconsOutline.calendar, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sm100(context).copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
