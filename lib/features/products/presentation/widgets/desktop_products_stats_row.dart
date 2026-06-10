import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_header_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Row of large, clickable overview cards (All / Active / Out of Stock)
/// plus an informational Categories tile. Doubles as the desktop filter
/// bar — selecting a card drives [ProductQuickFilter] the same way the
/// mobile mini stats do, mirroring `DesktopInventoryStatsRow`.
class DesktopProductsStatsRow extends StatelessWidget {
  final List<ProductData> products;
  final int categoryCount;
  final bool isRestaurant;
  final ProductQuickFilter selectedFilter;
  final ValueChanged<ProductQuickFilter> onFilterChanged;

  const DesktopProductsStatsRow({
    super.key,
    required this.products,
    required this.categoryCount,
    required this.isRestaurant,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final total = products.length;
    final active = products.where((p) => p.isActive == true).length;
    final outOfStock = products.where((p) => (p.stockLevel ?? 0) <= 0).length;

    final cards = <_StatCardData>[
      _StatCardData(
        filter: ProductQuickFilter.all,
        label: 'All Items',
        value: total,
        total: total,
        icon: isRestaurant ? SolarIconsOutline.chefHat : SolarIconsOutline.bag5,
        color: colors.primary,
      ),
      _StatCardData(
        filter: ProductQuickFilter.active,
        label: 'Active',
        value: active,
        total: total,
        icon: SolarIconsOutline.checkCircle,
        color: colors.success,
      ),
      if (!isRestaurant)
        _StatCardData(
          filter: ProductQuickFilter.outOfStock,
          label: 'Out of Stock',
          value: outOfStock,
          total: total,
          icon: SolarIconsOutline.bagCross,
          color: colors.danger,
        ),
      _StatCardData(
        filter: null,
        label: 'Categories',
        value: categoryCount,
        total: categoryCount,
        icon: SolarIconsOutline.layersMinimalistic,
        color: colors.info,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i != 0) const SizedBox(width: AppDims.s3),
          Expanded(
            child: _StatCard(
              data: cards[i],
              isSelected: cards[i].filter != null &&
                  selectedFilter == cards[i].filter,
              onTap: cards[i].filter == null
                  ? null
                  : () => onFilterChanged(cards[i].filter!),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCardData {
  final ProductQuickFilter? filter;
  final String label;
  final int value;
  final int total;
  final IconData icon;
  final Color color;

  const _StatCardData({
    required this.filter,
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatefulWidget {
  final _StatCardData data;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final data = widget.data;
    final ratio = data.total == 0 ? 0.0 : data.value / data.total;
    final selected = widget.isSelected;
    final interactive = widget.onTap != null;

    return MouseRegion(
      cursor: interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: selected
                ? data.color.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rXl),
            border: Border.all(
              color: selected
                  ? data.color.withValues(alpha: 0.45)
                  : _hovered
                      ? data.color.withValues(alpha: 0.30)
                      : colors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: _hovered || selected
                ? [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                    child: Icon(data.icon, color: data.color, size: 18),
                  ),
                  const Spacer(),
                  if (interactive)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: selected ? 0 : -0.125,
                      child: Icon(
                        SolarIconsBold.altArrowRight,
                        size: 16,
                        color: selected
                            ? data.color
                            : colors.textHint.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDims.s4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${data.value}',
                  style: AppTextStyles.lg100(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: AppTextStyles.sm300(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDims.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: colors.border.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(data.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
