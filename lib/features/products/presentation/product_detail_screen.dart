import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/product_form_screen.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_stock_panel.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_row.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductData product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final bool _isRestaurant;

  @override
  void initState() {
    super.initState();

    _isRestaurant = context.read<AuthBloc>().state.permissions.isRestaurant;
    if (_isRestaurant) return;

    final inventoryBloc = context.read<InventoryBloc>();
    if (inventoryBloc.state.status == InventoryStatus.initial &&
        inventoryBloc.state.stockList.isEmpty) {
      inventoryBloc.add(const OnInventoryInitial());
    }

    final expiryBloc = context.read<ExpiryBloc>();
    if (expiryBloc.state.status == ExpiryStatus.initial &&
        expiryBloc.state.alerts.isEmpty) {
      expiryBloc.add(const OnExpiryAlertsInitial());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocSelector<ProductBloc, ProductState, ProductData?>(
      selector: (state) {
        for (final p in state.products) {
          if (p.id == widget.product.id) return p;
        }
        return null;
      },
      builder: (context, latest) {
        final product = latest ?? widget.product;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                _NavBar(product: product),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s2,
                      AppDims.s4,
                      AppDims.s6 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      _Hero(product: product),
                      if (!_isRestaurant)
                        product.trackInventory == false
                            ? const ProductStockNotTracked()
                            : ProductStockPanel(product: product),
                      _Details(product: product),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  final ProductData product;

  const _NavBar({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      DirectionalIcon(
                        icon: PhosphorIconsRegular.caretLeft,
                        size: 22,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        tr.navProducts,
                        style: TextStyle(fontSize: 17, color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Catalog writes are owner/manager only.
            if (context.select<AuthBloc, bool>(
              (b) => b.state.permissions.canEditCatalog,
            ))
              Pressable(
                key: const ValueKey('product-edit'),
                onTap: () => openProductForm(context, product: product),
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(
                        tr.edit,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ProductData product;

  const _Hero({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final name = productDisplayName(context, product);
    final category = product.categoryName?.trim();
    final currency = context.select<DashboardSummaryBloc, String>(
      (b) => b.state.summary?.currency ?? 'SDG',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Row(
        children: [
          ProductThumb(product: product, size: 84, radius: 22),
          const SizedBox(width: AppDims.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textDirection: name.contentDirection,
                  style: TextStyle(
                    fontSize: 24,
                    height: 29 / 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (category != null && category.isNotEmpty)
                      ? category
                      : tr.noCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
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
                        formatPrice(product.price),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFeatures: AppTextStyles.tabularFigures,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currency,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final ProductData product;

  const _Details({required this.product});

  String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final sku = _clean(product.sku);
    final barcode = _clean(product.barcode);
    final unit = _clean(product.unit);
    final desc = _clean(product.description);

    final rows = <Widget>[
      if (sku != null) DetailRow(label: tr.fieldSku, value: sku, numeric: true),
      if (barcode != null)
        DetailRow(label: tr.pfBarcode, value: barcode, numeric: true),
      if (unit != null) DetailRow(label: tr.pfUnit, value: unit),
      if (desc != null) DetailTextRow(label: tr.fieldDescription, value: desc),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSectionLabel(tr.pcDetails),
        AppFormGroup(children: rows),
      ],
    );
  }
}
