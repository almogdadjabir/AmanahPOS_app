import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/common/localization/app_localizations_product_extensions.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/features/products/presentation/widgets/delete_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/edit_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_stock_section_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double kDesktopDrawerWidth = 460.0;

/// Right-side desktop panel that slides in when a product is tapped.
/// Replaces the full-screen route on desktop with an overlay drawer that
/// keeps the product list visible behind a soft scrim.
class DesktopProductDetailDrawer extends StatefulWidget {
  final ProductData product;
  final VoidCallback onClose;

  const DesktopProductDetailDrawer({
    super.key,
    required this.product,
    required this.onClose,
  });

  @override
  State<DesktopProductDetailDrawer> createState() =>
      _DesktopProductDetailDrawerState();
}

class _DesktopProductDetailDrawerState
    extends State<DesktopProductDetailDrawer> {
  late final bool _showStock;

  @override
  void initState() {
    super.initState();
    _showStock = !context.read<AuthBloc>().state.permissions.isRestaurant;
    _maybeInitBlocs();
  }

  void _maybeInitBlocs() {
    if (!_showStock) return;
    final inv = context.read<InventoryBloc>();
    if (inv.state.status == InventoryStatus.initial &&
        inv.state.stockList.isEmpty) {
      inv.add(const OnInventoryInitial());
    }
    final exp = context.read<ExpiryBloc>();
    if (exp.state.status == ExpiryStatus.initial && exp.state.alerts.isEmpty) {
      exp.add(const OnExpiryAlertsInitial());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) =>
          prev.submitStatus != curr.submitStatus &&
          curr.submitStatus == ProductSubmitStatus.success,
      listener: (context, state) {
        final stillExists = state.products.any(
          (p) => p.id == widget.product.id,
        );
        if (!stillExists) widget.onClose();
      },
      child: BlocSelector<ProductBloc, ProductState, ProductData?>(
        selector: (state) {
          for (final p in state.products) {
            if (p.id == widget.product.id) return p;
          }
          return null;
        },
        builder: (context, latestProduct) {
          final product = latestProduct ?? widget.product;
          return _DrawerBody(
            product: product,
            showStock: _showStock,
            onClose: widget.onClose,
          );
        },
      ),
    );
  }
}

// ── Drawer body ───────────────────────────────────────────────────────────────

class _DrawerBody extends StatelessWidget {
  final ProductData product;
  final bool showStock;
  final VoidCallback onClose;

  const _DrawerBody({
    required this.product,
    required this.showStock,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final margin = _computeMargin(product);
    final hasDetails = _hasAnyDetail(product);
    final hasAlerts =
        showStock &&
        (product.minStockLevel != null || product.expiryAlertDays != null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(
          start: BorderSide(
            color: colors.primary.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 40,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Hero image ──────────────────────────────────────────────────
          _ImageHeader(product: product, onClose: onClose),

          // ── Scrollable content ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickStatsRow(product: product, showStock: showStock)
                      .mAnimate()
                      .fadeIn(delay: 50.ms, duration: 200.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 200.ms,
                        curve: Curves.easeOut,
                      ),

                  if (margin != null) ...[
                    const SizedBox(height: AppDims.s3),
                    _MarginCard(product: product, margin: margin)
                        .mAnimate()
                        .fadeIn(delay: 90.ms, duration: 200.ms)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 200.ms,
                          curve: Curves.easeOut,
                        ),
                  ],

                  if (hasDetails) ...[
                    const SizedBox(height: AppDims.s3),
                    _DetailsCard(product: product)
                        .mAnimate()
                        .fadeIn(delay: 130.ms, duration: 200.ms)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 200.ms,
                          curve: Curves.easeOut,
                        ),
                  ],

                  if (hasAlerts) ...[
                    const SizedBox(height: AppDims.s3),
                    _AlertsCard(product: product)
                        .mAnimate()
                        .fadeIn(delay: 160.ms, duration: 200.ms)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 200.ms,
                          curve: Curves.easeOut,
                        ),
                  ],

                  if (showStock) ...[
                    const SizedBox(height: AppDims.s5),
                    WorkspaceSectionHeader(
                      title: context.tr.stockByShop,
                    ).mAnimate().fadeIn(delay: 180.ms, duration: 200.ms),
                    const SizedBox(height: AppDims.s3),
                    ProductStockSectionView(
                      product: product,
                    ).mAnimate().fadeIn(delay: 200.ms, duration: 220.ms),
                  ],
                ],
              ),
            ),
          ),

          // ── Sticky action bar ───────────────────────────────────────────
          _ActionBar(product: product),
        ],
      ),
    );
  }

  static double? _computeMargin(ProductData product) {
    final price = _toDouble(product.price);
    final cost = _toDouble(product.costPrice);
    if (price == null || cost == null || price <= 0) return null;
    return (price - cost) / price * 100;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _hasAnyDetail(ProductData product) =>
      (product.sku?.trim().isNotEmpty == true) ||
      (product.barcode?.trim().isNotEmpty == true) ||
      (product.description?.trim().isNotEmpty == true) ||
      (product.unit?.trim().isNotEmpty == true) ||
      product.createdAt != null;
}

// ── Image hero header ─────────────────────────────────────────────────────────

class _ImageHeader extends StatefulWidget {
  final ProductData product;
  final VoidCallback onClose;

  const _ImageHeader({required this.product, required this.onClose});

  @override
  State<_ImageHeader> createState() => _ImageHeaderState();
}

class _ImageHeaderState extends State<_ImageHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final product = widget.product;
    final imageUrl = product.detailImageUrl;
    final isActive = product.isActive != false;
    final categoryName = product.categoryName?.trim();
    final productName = product.name?.trim();
    final displayName = productName?.isNotEmpty == true
        ? productName!
        : context.tr.product;

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Product image with hover zoom ────────────────────────────────
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: imageUrl != null
                ? OfflineCachedImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      .mAnimate(target: _hovered ? 1 : 0)
                      .scaleXY(
                        begin: 1.0,
                        end: 1.04,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withValues(alpha: 0.14),
                          colors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        SolarIconsOutline.bag5,
                        size: 52,
                        color: colors.primary.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
          ),

          // ── Cinematic gradient overlay ────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.60, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x55000000),
                  Color(0xDD000000),
                ],
              ),
            ),
          ),

          // ── Close button ──────────────────────────────────────────────────
          PositionedDirectional(
            top: AppDims.s3,
            end: AppDims.s3,
            child: _GlassIconButton(
              icon: Icons.close_rounded,
              onTap: widget.onClose,
            ),
          ),

          // ── Inactive badge ────────────────────────────────────────────────
          if (!isActive)
            PositionedDirectional(
              top: AppDims.s3,
              start: AppDims.s3,
              child: _GlassPill(
                label: context.tr.inactive,
                textColor: Colors.red.shade300,
                bgColor: Colors.black.withValues(alpha: 0.55),
              ),
            ),

          // ── Bottom info: category + name ──────────────────────────────────
          PositionedDirectional(
            bottom: AppDims.s4,
            start: AppDims.s4,
            end: AppDims.s4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (categoryName != null && categoryName.isNotEmpty) ...[
                  _GlassPill(label: categoryName),
                  const SizedBox(height: AppDims.s2),
                ],
                // Full width so a single-line RTL name aligns to the right
                // instead of shrink-wrapping at the left edge.
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: displayName.contentDirection,
                    style: AppTextStyles.bs500(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                      shadows: const [
                        Shadow(color: Color(0x55000000), blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).mAnimate().fadeIn(duration: 160.ms);
  }
}

// ── Glass UI components ───────────────────────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.42),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _GlassPill({
    required this.label,
    this.textColor = Colors.white,
    this.bgColor = const Color(0x30FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: AppTextStyles.sm200(
            context,
          ).copyWith(color: textColor, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ── Quick stats row ───────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final ProductData product;
  final bool showStock;

  const _QuickStatsRow({required this.product, required this.showStock});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final isActive = product.isActive != false;
    final stock = product.stockLevel ?? 0;

    final tiles = <({IconData icon, String label, String value, Color color})>[
      (
        icon: SolarIconsOutline.walletMoney,
        label: tr.price,
        value: _fmtPrice(product.price),
        color: colors.primary,
      ),
      if (showStock)
        (
          icon: SolarIconsOutline.box,
          label: tr.stock,
          value: _fmtQty(stock),
          color: _stockColor(stock),
        ),
      (
        icon: isActive
            ? SolarIconsOutline.checkCircle
            : SolarIconsOutline.pauseCircle,
        label: tr.status,
        value: isActive ? tr.active : tr.inactive,
        color: isActive ? const Color(0xFF16A34A) : colors.textHint,
      ),
      if (product.unit?.trim().isNotEmpty == true)
        (
          icon: SolarIconsOutline.tuning,
          label: tr.fieldUnit,
          value: product.unit!.trim(),
          color: colors.info,
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i != 0) const SizedBox(width: AppDims.s2),
          Expanded(
            child: _StatTile(
              icon: tiles[i].icon,
              label: tiles[i].label,
              value: tiles[i].value,
              color: tiles[i].color,
            ),
          ),
        ],
      ],
    );
  }

  static String _fmtPrice(dynamic v) {
    if (v == null) return '–';
    if (v is num) {
      return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    }
    final d = double.tryParse(v.toString());
    return d != null
        ? d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2)
        : v.toString();
  }

  static String _fmtQty(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  static Color _stockColor(double v) {
    if (v <= 0) return const Color(0xFFDC2626);
    if (v <= 5) return const Color(0xFFEA580C);
    return const Color(0xFF16A34A);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: AppDims.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.sm100(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profit margin card ────────────────────────────────────────────────────────

class _MarginCard extends StatelessWidget {
  final ProductData product;
  final double margin;

  const _MarginCard({required this.product, required this.margin});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final color = margin >= 30
        ? const Color(0xFF16A34A)
        : margin >= 10
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDims.rSm),
                  ),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(
                      SolarIconsOutline.chart,
                      color: color,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Text(
                  'Profit Margin',
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: AppTextStyles.bs300(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s3),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (margin / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: colors.border.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: AppDims.s3),
            Row(
              children: [
                _MarginStat(
                  label: tr.fieldCostPrice,
                  value: _fmtPrice(product.costPrice),
                ),
                const SizedBox(width: AppDims.s5),
                _MarginStat(label: tr.price, value: _fmtPrice(product.price)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtPrice(dynamic v) {
    if (v == null) return '–';
    if (v is num) return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    final d = double.tryParse(v.toString());
    return d != null
        ? d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2)
        : '–';
  }
}

class _MarginStat extends StatelessWidget {
  final String label;
  final String value;

  const _MarginStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.sm100(
            context,
          ).copyWith(color: colors.textSecondary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.bs300(
            context,
          ).copyWith(color: colors.textPrimary, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

// ── Product details card ──────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final ProductData product;

  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final rows = <_DetailItem>[];

    final sku = product.sku?.trim();
    if (sku != null && sku.isNotEmpty) {
      rows.add(
        _DetailItem(
          icon: SolarIconsOutline.tag,
          label: tr.fieldSku,
          value: sku,
          copyable: true,
        ),
      );
    }

    final barcode = product.barcode?.trim();
    if (barcode != null && barcode.isNotEmpty) {
      rows.add(
        _DetailItem(
          icon: SolarIconsOutline.qrCode,
          label: tr.fieldBarcode,
          value: barcode,
          copyable: true,
        ),
      );
    }

    final unit = product.unit?.trim();
    if (unit != null && unit.isNotEmpty) {
      rows.add(
        _DetailItem(
          icon: SolarIconsOutline.tuning,
          label: tr.fieldUnit,
          value: unit,
          copyable: false,
        ),
      );
    }

    final desc = product.description?.trim();
    if (desc != null && desc.isNotEmpty) {
      rows.add(
        _DetailItem(
          icon: SolarIconsOutline.documentText,
          label: tr.fieldDescription,
          value: desc,
          copyable: false,
          multiLine: true,
        ),
      );
    }

    if (product.createdAt != null) {
      rows.add(
        _DetailItem(
          icon: SolarIconsOutline.calendarDate,
          label: 'Created',
          value: _fmtDate(product.createdAt!),
          copyable: false,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _DetailsRowWidget(item: rows[i]),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.border.withValues(alpha: 0.5),
                indent: AppDims.s4 + 36 + AppDims.s3,
                endIndent: AppDims.s4,
              ),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final bool multiLine;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.copyable,
    this.multiLine = false,
  });
}

class _DetailsRowWidget extends StatelessWidget {
  final _DetailItem item;

  const _DetailsRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s3,
        AppDims.s3,
      ),
      child: Row(
        crossAxisAlignment: item.multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rSm),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(item.icon, size: 16, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: item.multiLine ? null : 1,
                  overflow: item.multiLine ? null : TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (item.copyable) ...[
            const SizedBox(width: AppDims.s2),
            _CopyButton(value: item.value),
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String value;

  const _CopyButton({required this.value});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.value));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copied to clipboard'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
          child: Icon(
            SolarIconsOutline.copy,
            size: 15,
            color: _hovered ? colors.primary : colors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Alerts card ───────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  final ProductData product;

  const _AlertsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final minStock = product.minStockLevel;
    final expiryDays = product.expiryAlertDays;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Column(
          children: [
            if (minStock != null) ...[
              _AlertBadge(
                icon: SolarIconsOutline.dangerTriangle,
                label: tr.fieldMinStockLevel,
                value: _fmtQty(minStock),
                color: const Color(0xFFF59E0B),
              ),
              if (expiryDays != null) const SizedBox(height: AppDims.s2),
            ],
            if (expiryDays != null)
              _AlertBadge(
                icon: SolarIconsOutline.calendarMark,
                label: tr.fieldExpiryAlert,
                value: tr.dayCountLabel(expiryDays),
                color: const Color(0xFFEA580C),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtQty(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _AlertBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AlertBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bs200(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky action bar ─────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final ProductData product;

  const _ActionBar({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: _DrawerActionButton(
                icon: SolarIconsOutline.penNewSquare,
                label: tr.edit,
                color: colors.primary,
                onTap: () => showEditProductSheet(context, product: product),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: _DrawerActionButton(
                icon: SolarIconsOutline.trashBinTrash,
                label: tr.delete,
                color: const Color(0xFFDC2626),
                onTap: () => showDeleteProductSheet(context, product: product),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DrawerActionButton> createState() => _DrawerActionButtonState();
}

class _DrawerActionButtonState extends State<_DrawerActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 44,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hovered ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: widget.color.withValues(alpha: _hovered ? 0.28 : 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: AppDims.s2),
              Text(
                widget.label,
                style: AppTextStyles.bs200(
                  context,
                ).copyWith(color: widget.color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
