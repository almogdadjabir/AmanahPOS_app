import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Right-hand column of the desktop products layout: a quick "Add product"
/// action, the category list doubling as a filter, and (for shops) a
/// "Needs attention" triage panel for low/out-of-stock items — mirrors
/// `DesktopInventorySidebar`.
class DesktopProductsSidebar extends StatelessWidget {
  final List<ProductData> products;
  final List<CategoryData> categories;
  final String? selectedCategoryId;
  final bool isRestaurant;
  final void Function(ProductData)? onProductTap;

  const DesktopProductsSidebar({
    super.key,
    required this.products,
    required this.categories,
    required this.selectedCategoryId,
    required this.isRestaurant,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final attention = isRestaurant
        ? <ProductData>[]
        : (products.where((p) {
            if (p.trackInventory != true) return false;
            final stock = p.stockLevel ?? 0;
            final minStock = p.minStockLevel ?? 0;
            return stock <= 0 || (minStock > 0 && stock <= minStock);
          }).toList()
          ..sort((a, b) {
            final aOut = (a.stockLevel ?? 0) <= 0 ? 0 : 1;
            final bOut = (b.stockLevel ?? 0) <= 0 ? 0 : 1;
            return aOut.compareTo(bOut);
          }));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _QuickActionsCard(),
        const SizedBox(height: AppDims.s4),
        _CategoriesPanel(
          categories: categories,
          selectedCategoryId: selectedCategoryId,
        ),
        if (!isRestaurant) ...[
          const SizedBox(height: AppDims.s4),
          _SidebarPanel(
            icon: SolarIconsOutline.dangerTriangle,
            iconColor: context.appColors.stockLow,
            title: 'Needs Attention',
            count: attention.length,
            emptyIcon: SolarIconsOutline.checkCircle,
            emptyMessage: 'All stock levels look healthy',
            items: attention.take(6).toList(),
            itemBuilder: (item) => _AttentionRow(
              item: item,
              onProductTap: onProductTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          FilledButton.icon(
            onPressed: () => showAddProductSheet(context),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            icon: const Icon(
              SolarIconsOutline.addCircle,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              tr.addProduct,
              style: AppTextStyles.bs200(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Categories panel ─────────────────────────────────────────────────────────

class _CategoriesPanel extends StatelessWidget {
  final List<CategoryData> categories;
  final String? selectedCategoryId;

  const _CategoriesPanel({
    required this.categories,
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: SolarIconsOutline.layersMinimalistic,
            iconColor: colors.info,
            title: 'Categories',
            count: categories.length,
          ),
          const SizedBox(height: AppDims.s3),
          _CategoryRow(
            label: tr.allProducts,
            isSelected: selectedCategoryId == null,
            onTap: () => context.read<ProductBloc>().add(
                  const OnProductCategorySelected(categoryId: null),
                ),
          ),
          for (final category in categories) ...[
            const SizedBox(height: AppDims.s1),
            _CategoryRow(
              label: category.name?.trim().isNotEmpty == true
                  ? category.name!.trim()
                  : tr.unknownCategory,
              isSelected: selectedCategoryId == category.id,
              onTap: () => context.read<ProductBloc>().add(
                    OnProductCategorySelected(categoryId: category.id),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s2,
              vertical: AppDims.s2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: 0.10)
                  : _hovered
                      ? colors.surfaceSoft
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.textHint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sm300(context).copyWith(
                      color: selected ? colors.primary : colors.textPrimary,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    SolarIconsBold.checkCircle,
                    size: 15,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared panel chrome ──────────────────────────────────────────────────────

class _SidebarPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final IconData emptyIcon;
  final String emptyMessage;
  final List<ProductData> items;
  final Widget Function(ProductData item) itemBuilder;

  const _SidebarPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(icon: icon, iconColor: iconColor, title: title, count: count),
          if (items.isEmpty) ...[
            const SizedBox(height: AppDims.s4),
            Column(
              children: [
                Icon(
                  emptyIcon,
                  size: 26,
                  color: colors.textHint.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppDims.s2),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sm300(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s2),
          ] else ...[
            const SizedBox(height: AppDims.s3),
            for (var i = 0; i < items.length; i++) ...[
              if (i != 0) const SizedBox(height: AppDims.s2),
              itemBuilder(items[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;

  const _PanelHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.sm100(context).copyWith(
                color: iconColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Needs attention rows ─────────────────────────────────────────────────────

class _AttentionRow extends StatefulWidget {
  final ProductData item;
  final void Function(ProductData)? onProductTap;

  const _AttentionRow({required this.item, this.onProductTap});

  @override
  State<_AttentionRow> createState() => _AttentionRowState();
}

class _AttentionRowState extends State<_AttentionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final item = widget.item;
    final stock = item.stockLevel ?? 0;
    final isOut = stock <= 0;
    final color = isOut ? colors.danger : colors.stockLow;

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: _hovered ? colors.surfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name?.trim().isNotEmpty == true
                      ? item.name!.trim()
                      : tr.product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.categoryName?.trim().isNotEmpty == true
                      ? item.categoryName!.trim()
                      : tr.noCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Text(
            _formatQty(stock),
            style: AppTextStyles.bs200(context).copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: InkWell(
          onTap: () {
            if (widget.onProductTap != null) {
              widget.onProductTap!(item);
            } else {
              Navigator.of(context).pushNamed(
                RouteStrings.productDetailScreen,
                arguments: {'product': item},
              );
            }
          },
          borderRadius: BorderRadius.circular(AppDims.rMd),
          child: row,
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
