import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/localization/app_localizations_product_extensions.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/update_stock_screen.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Per-shop stock rows for one product from the inventory list.
List<StockData> productStockRows(List<StockData> list, ProductData product) {
  final id = product.id;
  if (id != null) return list.where((s) => s.product == id).toList();

  final name = product.name?.trim().toLowerCase();
  if (name == null || name.isEmpty) return const [];
  return list
      .where((s) => s.productName?.trim().toLowerCase() == name)
      .toList();
}

class ProductExpirySummary {
  final int expiredCount;
  final int expiringSoonCount;

  const ProductExpirySummary({
    required this.expiredCount,
    required this.expiringSoonCount,
  });

  bool get hasExpired => expiredCount > 0;
  bool get hasAlerts => expiredCount > 0 || expiringSoonCount > 0;

  factory ProductExpirySummary.from(List<StockData> rows) {
    var expired = 0;
    var soon = 0;
    for (final s in rows) {
      if (s.isExpiredSafe) expired++;
      if (s.isExpiringSoon) soon++;
    }
    return ProductExpirySummary(expiredCount: expired, expiringSoonCount: soon);
  }
}

/// Section label above a card, 13pt hint.
class DetailSectionLabel extends StatelessWidget {
  final String text;

  const DetailSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: context.appColors.textHint),
      ),
    );
  }
}

/// Stock card: total, status pill, per-shop rows, one Update stock action.
class ProductStockPanel extends StatelessWidget {
  final ProductData product;

  const ProductStockPanel({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final card = BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (p, c) => p.stockList != c.stockList || p.status != c.status,
      builder: (context, state) {
        final loading =
            (state.status == InventoryStatus.initial ||
                state.status == InventoryStatus.loading) &&
            state.stockList.isEmpty;
        final rows = productStockRows(state.stockList, product);

        final total =
            product.stockLevel ?? rows.fold<double>(0, (sum, r) => sum + r.qty);
        final level = productStockLevel(
          product.copyWith(stockLevel: total),
          isRestaurant: false,
        );

        final unit = (product.unit?.trim().isNotEmpty ?? false)
            ? product.unit!.trim()
            : tr.pcUnitsShort;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment:
                            Directionality.of(context) == TextDirection.rtl
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Text(
                            formatQty(total),
                            style: TextStyle(
                              fontSize: 46,
                              height: 50 / 46,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.4,
                              color: colors.textPrimary,
                              fontFeatures: AppTextStyles.tabularFigures,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(level: level, qty: formatQty(total)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: AppSkeleton(
                    child: Column(
                      children: [
                        Shimmer(width: double.infinity, height: 18, radius: 6),
                        SizedBox(height: 16),
                        Shimmer(width: double.infinity, height: 18, radius: 6),
                      ],
                    ),
                  ),
                )
              else if (rows.isEmpty)
                _KvRow(
                  label: tr.pcNoStockYet,
                  labelColor: colors.textHint,
                  showTopLine: false,
                )
              else
                for (var i = 0; i < rows.length; i++)
                  _KvRow(
                    label: rows[i].shopName ?? tr.shop,
                    value: formatQty(rows[i].qty),
                    valueColor: (rows[i].isOutOfStock ?? false)
                        ? colors.danger
                        : (rows[i].isLowStock ?? false)
                        ? colors.warning
                        : colors.textSecondary,
                    bold:
                        (rows[i].isOutOfStock ?? false) ||
                        (rows[i].isLowStock ?? false),
                    showTopLine: i > 0,
                  ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Pressable(
                  onTap: () => openUpdateStock(context, product: product),
                  haptic: true,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppDims.borderMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.package,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr.pcUpdateStock,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSectionLabel(tr.stock),
        card,
        BlocBuilder<InventoryBloc, InventoryState>(
          buildWhen: (p, c) => p.stockList != c.stockList,
          builder: (context, state) {
            final summary = ProductExpirySummary.from(
              productStockRows(state.stockList, product),
            );
            if (!summary.hasAlerts) return const SizedBox.shrink();
            return _ExpiryBanner(summary: summary);
          },
        ),
      ],
    );
  }
}

/// Shown instead of the stock card when the product does not track stock.
class ProductStockNotTracked extends StatelessWidget {
  const ProductStockNotTracked({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSectionLabel(tr.stock),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(AppDims.s4),
              child: Text(
                tr.pcStockNotTracked,
                style: TextStyle(fontSize: 15, color: colors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProductStockLevel level;
  final String qty;

  const _StatusPill({required this.level, required this.qty});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final (bg, fg, text) = switch (level) {
      ProductStockLevel.out => (
        colors.dangerContainer,
        colors.danger,
        tr.pcOutOfStock,
      ),
      ProductStockLevel.low => (
        colors.warningContainer,
        colors.warning,
        tr.pcLeft(qty),
      ),
      _ => (colors.successContainer, colors.success, tr.pcInStock(qty)),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? labelColor;
  final Color? valueColor;
  final bool bold;
  final bool showTopLine;

  const _KvRow({
    required this.label,
    this.value,
    this.labelColor,
    this.valueColor,
    this.bold = false,
    this.showTopLine = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        if (showTopLine)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppDims.s4,
            color: colors.border,
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      color: labelColor ?? colors.textPrimary,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    value!,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                      color: valueColor ?? colors.textSecondary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpiryBanner extends StatelessWidget {
  final ProductExpirySummary summary;

  const _ExpiryBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = summary.hasExpired ? colors.danger : colors.warning;
    final bg = summary.hasExpired
        ? colors.dangerContainer
        : colors.warningContainer;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Pressable(
        onTap: () =>
            Navigator.of(context).pushNamed(RouteStrings.expiryAlertsScreen),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  summary.hasExpired
                      ? PhosphorIconsRegular.warningCircle
                      : PhosphorIconsRegular.warning,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr.productExpirySummary(
                      expiredCount: summary.expiredCount,
                      expiringSoonCount: summary.expiringSoonCount,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 18,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only detail rows (label start, value end).
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool numeric;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 17, color: colors.textPrimary),
            ),
            const SizedBox(width: AppDims.s4),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                textDirection: numeric ? TextDirection.ltr : null,
                style: TextStyle(
                  fontSize: 17,
                  color: colors.textSecondary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Description row: label above a wrapped value.
class DetailTextRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailTextRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 17, color: colors.textPrimary),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                height: 21 / 15,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
