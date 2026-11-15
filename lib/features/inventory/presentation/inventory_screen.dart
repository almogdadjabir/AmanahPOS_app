import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/expiry_report_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/inbound_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/vendors_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/update_stock_screen.dart';
import 'package:amana_pos/features/products/presentation/widgets/option_picker_sheet.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_row.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_states.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stock tab: receive deliveries and see what needs attention. Not a second
/// product list: tapping a row opens the product, where stock is updated.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const int _minAttentionRows = 8;
  static const int _maxAutoPages = 15;

  final _scrollCtrl = ScrollController();
  int _autoPages = 0;
  bool _requestingMore = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const OnInventoryInitial());
    context.read<ExpiryBloc>().add(const OnExpiryAlertsInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  static bool _needsAttention(StockData s) =>
      (s.isLowStock ?? false) || (s.isOutOfStock ?? false);

  void _loadMore() {
    final state = context.read<InventoryBloc>().state;
    if (!state.hasMorePages ||
        state.status == InventoryStatus.loading ||
        state.status == InventoryStatus.loadingMore ||
        _requestingMore) {
      return;
    }
    _requestingMore = true;
    context.read<InventoryBloc>().add(const OnLoadMoreStock());
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _requestingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final p = _scrollCtrl.position;
    if (p.pixels >= p.maxScrollExtent - 260) _loadMore();
  }

  /// Keep pulling pages until the attention list has something to show.
  void _autoFill(InventoryState state) {
    if (state.status != InventoryStatus.success) return;
    if (!state.hasMorePages || _autoPages >= _maxAutoPages) return;
    final count = state.stockList.where(_needsAttention).length;
    if (count >= _minAttentionRows) return;
    _autoPages++;
    context.read<InventoryBloc>().add(const OnLoadMoreStock());
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    _autoPages = 0;
    final inventory = context.read<InventoryBloc>()
      ..add(const OnInventoryInitial());
    context.read<ExpiryBloc>().add(const OnExpiryAlertsInitial());
    await inventory.stream
        .firstWhere((s) => s.status == InventoryStatus.success)
        .timeout(const Duration(seconds: 6), onTimeout: () => inventory.state);
  }

  Future<void> _receive(bool premium) async {
    if (premium) {
      showInboundSheet(context);
      return;
    }
    final products = context
        .read<ProductBloc>()
        .state
        .products
        .where((p) => p.trackInventory == true)
        .toList();
    final picked = await showOptionPicker<ProductData>(
      context,
      title: context.tr.stReceive,
      selected: null,
      options: [
        for (final p in products)
          PickerOption(
            value: p,
            label: p.name ?? '',
            hint: (p.sku ?? '').isEmpty ? null : p.sku,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    await openUpdateStock(context, product: picked);
  }

  ProductData _productFor(StockData row) {
    final id = row.product;
    for (final p in context.read<ProductBloc>().state.products) {
      if (p.id == id) return p;
    }
    return ProductData(
      id: id,
      name: row.productName,
      sku: row.productSku,
      stockLevel: row.qty,
      trackInventory: true,
    );
  }

  ProductData? _knownProduct(StockData row) {
    for (final p in context.read<ProductBloc>().state.products) {
      if (p.id == row.product) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final premium = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canUseInventoryInboundReceiving,
    );
    final bottomInset =
        NavShell.contentHeight + MediaQuery.viewPaddingOf(context).bottom + 20;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: BlocListener<InventoryBloc, InventoryState>(
          listenWhen: (p, c) =>
              p.stockList != c.stockList || p.status != c.status,
          listener: (context, state) => _autoFill(state),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      Pressable(
                        onTap: () => _receive(premium),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            PhosphorIconsRegular.plus,
                            size: 26,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _refresh),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        bottomInset,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          AppLargeTitle(title: tr.navInventory),
                          _ReceiveCard(
                            premium: premium,
                            onTap: () => _receive(premium),
                          ),
                          const SizedBox(height: 14),
                          const _Tiles(),
                          _AttentionSection(
                            productFor: _productFor,
                            knownProduct: _knownProduct,
                          ),
                          if (premium) const _MoreGroup(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiveCard extends StatelessWidget {
  final bool premium;
  final VoidCallback onTap;

  const _ReceiveCard({required this.premium, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.package,
                    size: 20,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        premium ? tr.stReceive : tr.stAddStock,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (premium)
                        Text(
                          tr.stReceiveHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (p, c) =>
          p.stockList != c.stockList || p.hasMorePages != c.hasMorePages,
      builder: (context, inv) {
        var low = 0;
        var out = 0;
        for (final s in inv.stockList) {
          if (s.isOutOfStock ?? false) {
            out++;
          } else if (s.isLowStock ?? false) {
            low++;
          }
        }
        final plus = inv.hasMorePages ? '+' : '';

        return BlocBuilder<ExpiryBloc, ExpiryState>(
          buildWhen: (p, c) => p.alerts != c.alerts,
          builder: (context, expiry) {
            Widget tile(String value, String label, Color color) {
              return Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppDims.borderLg,
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: color,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Row(
              children: [
                tile('$low$plus', tr.pcChipLow, colors.warning),
                const SizedBox(width: 10),
                tile('$out$plus', tr.pcChipOut, colors.danger),
                const SizedBox(width: 10),
                tile('${expiry.alerts.length}', tr.stExpiring, colors.warning),
              ],
            );
          },
        );
      },
    );
  }
}

class _AttentionSection extends StatelessWidget {
  final ProductData Function(StockData) productFor;
  final ProductData? Function(StockData) knownProduct;

  const _AttentionSection({
    required this.productFor,
    required this.knownProduct,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (p, c) =>
          p.stockList != c.stockList ||
          p.status != c.status ||
          p.hasMorePages != c.hasMorePages,
      builder: (context, state) {
        final loading =
            (state.status == InventoryStatus.initial ||
                state.status == InventoryStatus.loading) &&
            state.stockList.isEmpty;
        final rows = state.stockList
            .where((s) => (s.isLowStock ?? false) || (s.isOutOfStock ?? false))
            .toList(growable: false);

        final Widget body;
        if (loading) {
          body = const _AttentionSkeleton();
        } else if (state.status == InventoryStatus.failure &&
            state.stockList.isEmpty) {
          body = ProductsStateCard(
            icon: PhosphorIconsRegular.wifiSlash,
            tone: ProductsStateTone.danger,
            title: tr.somethingWentWrong,
            body: state.responseError ?? tr.pcErrorBody,
            actionLabel: tr.retry,
            onAction: () =>
                context.read<InventoryBloc>().add(const OnInventoryInitial()),
          );
        } else if (rows.isEmpty) {
          body = state.hasMorePages
              ? const _AttentionSkeleton()
              : ProductsStateCard(
                  icon: PhosphorIconsRegular.checkCircle,
                  title: tr.stAllGood,
                  body: tr.stAllGoodBody,
                );
        } else {
          body = DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppDims.borderLg,
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: AppDims.borderLg,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: AppDims.s4 + 44 + AppDims.s3,
                        color: colors.border,
                      ),
                    _AttentionRow(
                      row: rows[i],
                      product: productFor(rows[i]),
                      showPrice: knownProduct(rows[i]) != null,
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
              child: Text(
                tr.stAttention,
                style: TextStyle(fontSize: 13, color: colors.textHint),
              ),
            ),
            SizedBox(width: double.infinity, child: body),
            if (state.status == InventoryStatus.loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDims.s4),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final StockData row;
  final ProductData product;
  final bool showPrice;

  const _AttentionRow({
    required this.row,
    required this.product,
    required this.showPrice,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    final out = row.isOutOfStock ?? false;
    final qty = formatQty(row.qty);
    final stockText = out ? tr.pcOutOfStock : tr.pcLeft(qty);
    final shop = row.shopName?.trim();
    final subtitle = [
      if (shop != null && shop.isNotEmpty) shop,
      stockText,
    ].join(' · ');
    final name = productDisplayName(context, product);

    return Pressable(
      onTap: () => openProductDetail(context, product),
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            child: Row(
              children: [
                ProductThumb(product: product),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge!.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall!.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: out ? colors.danger : colors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showPrice) ...[
                  const SizedBox(width: AppDims.s2),
                  Text(
                    formatPrice(product.price),
                    textDirection: TextDirection.ltr,
                    style: text.bodyLarge!
                        .copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        )
                        .tabular,
                  ),
                ],
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionSkeleton extends StatelessWidget {
  const _AttentionSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSkeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 44 + AppDims.s3,
                  color: colors.border,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.s4,
                  vertical: AppDims.s2,
                ),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Shimmer(width: 44, height: 44, radius: 11),
                      SizedBox(width: AppDims.s3),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer(width: 140, height: 15, radius: 6),
                            SizedBox(height: 8),
                            Shimmer(width: 90, height: 11, radius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Premium only: Vendors, Receipts, Expiry report.
class _MoreGroup extends StatelessWidget {
  const _MoreGroup();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: AppGroup(
        header: tr.stMore,
        children: [
          AppGroupRow(
            icon: PhosphorIconsRegular.users,
            tint: AppTint.digital,
            title: tr.stVendors,
            onTap: () => showVendorsSheet(context),
          ),
          AppGroupRow(
            icon: PhosphorIconsRegular.receipt,
            tint: AppTint.neutral,
            title: tr.stReceipts,
            onTap: () => showInboundHistorySheet(context),
          ),
          AppGroupRow(
            icon: PhosphorIconsRegular.clock,
            tint: AppTint.warning,
            title: tr.stExpiryReport,
            onTap: () => showExpiryReportSheet(context),
          ),
        ],
      ),
    );
  }
}
