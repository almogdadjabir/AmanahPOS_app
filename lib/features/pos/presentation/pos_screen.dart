import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/cart/presentation/desktop_cart_panel.dart';
import 'package:amana_pos/features/cart/presentation/products_empty.dart';
import 'package:amana_pos/features/cart/presentation/products_loading_grid.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/category_bar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/desktop_category_sidebar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/desktop_pos_top_bar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_search_section.dart';
import 'package:amana_pos/features/pos/presentation/widgets/product_grid.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  bool _checkoutResolvingShop = false;

  @override
  void initState() {
    super.initState();

    final productState = context.read<ProductBloc>().state;
    if (productState.products.isEmpty) {
      context.read<ProductBloc>().add(const OnProductInitial());
    }

    final businessState = context.read<BusinessBloc>().state;
    if (businessState.businessList == null ||
        businessState.businessList!.isEmpty) {
      context.read<BusinessBloc>().add(OnBusinessInitial());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchTaxConfig();
      _autoSelectShop();
      _loadDashboardSummary();
    });
  }

  void _dispatchTaxConfig() {
    if (!mounted) return;
    // BusinessBloc has the freshest copy after a refresh; AuthBloc's
    // defaultBusiness covers cold offline starts (loaded from SQLite cache).
    final businessList = context.read<BusinessBloc>().state.businessList;
    final business = (businessList != null && businessList.isNotEmpty)
        ? businessList.first
        : context.read<AuthBloc>().state.defaultBusiness;
    context
        .read<PosBloc>()
        .add(PosTaxConfigChanged(TaxConfig.fromBusiness(business)));
  }

  void _loadDashboardSummary({bool forceRefresh = false}) {
    if (!mounted) return;

    final shopId = context.read<PosBloc>().state.selectedShopId;

    context.read<DashboardSummaryBloc>().add(
      OnDashboardSummaryStarted(
        shopId: shopId,
        topSellersLimit: 5,
        forceRefresh: forceRefresh,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _desktopRefresh() async {
    if (!mounted) return;
    context.read<ProductBloc>().add(const OnProductInitial(force: true));
    context.read<BusinessBloc>().add(OnBusinessInitial());
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final shopId =
        _autoSelectShop() ?? context.read<PosBloc>().state.selectedShopId;
    context.read<DashboardSummaryBloc>().add(
      OnDashboardSummaryRefreshRequested(shopId: shopId, topSellersLimit: 10),
    );
  }

  String? _autoSelectShop() {
    if (!mounted) return null;

    final posState = context.read<PosBloc>().state;
    if (posState.selectedShopId != null &&
        posState.selectedShopId!.isNotEmpty) {
      return posState.selectedShopId;
    }

    final permissions = context.read<AuthBloc>().state.permissions;

    if (permissions.isCashier) {
      final assignedId = context.read<AuthBloc>().state.profile?.defaultShopId;

      if (assignedId != null && assignedId.isNotEmpty) {
        context.read<PosBloc>().add(
          PosShopSelected(
            shopId: assignedId,
            shopName:
                context.read<AuthBloc>().state.profile?.defaultShopName ??
                'Your shop',
          ),
        );

        return assignedId;
      }

      return null;
    }

    final shops = _activeShops();

    if (shops.isEmpty) return null;

    final first = shops.first;
    final shopId = first.id;

    if (shopId == null || shopId.isEmpty) return null;

    context.read<PosBloc>().add(
      PosShopSelected(shopId: shopId, shopName: first.name ?? 'Shop'),
    );

    return shopId;
  }

  List<ShopData> _activeShops() {
    final fromBusiness = context
        .read<BusinessBloc>()
        .state
        .businessList
        ?.expand((b) => b.shops ?? <ShopData>[])
        .where((s) => s.id != null && (s.isActive ?? true))
        .toList();

    if (fromBusiness != null && fromBusiness.isNotEmpty) return fromBusiness;

    return context
            .read<AuthBloc>()
            .state
            .defaultBusiness
            ?.shops
            ?.where((s) => s.id != null && (s.isActive ?? true))
            .toList() ??
        [];
  }

  Future<void> _handleCheckout() async {
    if (_checkoutResolvingShop) return;
    _checkoutResolvingShop = true;

    try {
      final posState = context.read<PosBloc>().state;
      if (posState.paymentMethod == 'bankak') {
        String? bankakAccount;
        try {
          bankakAccount = context
              .read<AuthBloc>()
              .state
              .profile
              ?.bankakAccount
              ?.accountNumber
              ?.trim();
        } catch (_) {}

        if (bankakAccount == null || bankakAccount.isEmpty) {
          GlobalSnackBar.show(
            message: context.tr.posBankakNotSetup,
            isError: true,
            isAutoDismiss: false,
          );
          return;
        }
      }

      final shopId = posState.selectedShopId;

      if (shopId == null || shopId.isEmpty) {
        final fallback = await _shopFromCache();
        if (!mounted) return;

        if (fallback == null) {
          final permissions = context.read<AuthBloc>().state.permissions;
          final message = permissions.isCashier
              ? context.tr.posCashierNotAssigned
              : context.tr.posNoShopFound;
          GlobalSnackBar.show(
            message: message,
            isError: true,
            isAutoDismiss: false,
          );
          return;
        }

        context.read<PosBloc>().add(
          PosShopSelected(shopId: fallback, shopName: 'Shop'),
        );
        context.read<PosBloc>().add(PosCheckoutSubmitted(shopId: fallback));
        return;
      }

      context.read<PosBloc>().add(PosCheckoutSubmitted(shopId: shopId));
    } finally {
      _checkoutResolvingShop = false;
    }
  }

  Future<String?> _shopFromCache() async {
    try {
      final cache = getIt<OfflineLocalCache>();
      final cachedShops = await cache.getShops();
      if (cachedShops.isNotEmpty) {
        final id = cachedShops.first.id;
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BusinessBloc, BusinessState>(
          listenWhen: (prev, curr) => prev.businessList != curr.businessList,
          listener: (context, _) => _dispatchTaxConfig(),
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.defaultBusiness != curr.defaultBusiness,
          listener: (context, _) => _dispatchTaxConfig(),
        ),
        BlocListener<PosBloc, PosState>(
          listenWhen: (prev, curr) =>
              prev.submitStatus != curr.submitStatus ||
              prev.submitError != curr.submitError,
          listener: (context, state) {
            if (state.submitStatus == PosSubmitStatus.idle &&
                state.submitError?.isNotEmpty == true) {
              GlobalSnackBar.show(message: state.submitError!, isError: true);
              context.read<PosBloc>().add(const PosAcknowledgeSubmit());
              return;
            }

            if (state.submitStatus == PosSubmitStatus.success) {
              context.read<ProductBloc>().add(
                OnProductsSoldLocally(
                  soldQuantities: state.lastSoldQuantities,
                ),
              );

              // On desktop the receipt sheet is shown by DesktopCartPanel's own
              // BlocListener, so the snackbar would stack on top of it.
              if (!context.isDesktop) {
                final message = state.submitError?.isNotEmpty == true
                    ? state.submitError!
                    : context.tr.posSaleCompleted;
                GlobalSnackBar.show(message: message, isInfo: true);
              }
              context.read<PosBloc>().add(const PosAcknowledgeSubmit());

              final shopId =
                  _autoSelectShop() ??
                  context.read<PosBloc>().state.selectedShopId;

              context.read<DashboardSummaryBloc>().add(
                OnDashboardSummaryRefreshRequested(
                  shopId: shopId,
                  topSellersLimit: 10,
                ),
              );
            }

            if (state.submitStatus == PosSubmitStatus.failure) {
              final raw = state.submitError ?? context.tr.posFailedSale;
              final message = raw.contains('BANKAK_ACCOUNT_REQUIRED')
                  ? context.tr.posBankakRequired
                  : raw.contains('SHOP_MISMATCH')
                  ? context.tr.posShopMismatch
                  : raw;

              GlobalSnackBar.show(
                message: message,
                isError: true,
                isAutoDismiss: false,
              );
              context.read<PosBloc>().add(const PosAcknowledgeSubmit());
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<PosBloc, PosState>(
            buildWhen: (prev, curr) => prev.cartExpanded != curr.cartExpanded,
            builder: (context, posState) {
              // Shared product pane content used by both layouts
              final productPane = Column(
                children: [
                  BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
                    buildWhen: (prev, curr) =>
                        prev.status != curr.status ||
                        prev.summary != curr.summary,
                    builder: (context, state) {
                      final authState = context.read<AuthBloc>().state;
                      final summary = state.summary;
                      final shift = summary?.shift;

                      final isCashier = authState.permissions.isCashier;

                      final cashierName =
                          shift?.cashierName?.trim().isNotEmpty == true
                          ? shift!.cashierName!
                          : authState.profile?.fullName ?? 'Cashier';

                      final shiftStart =
                          DateTime.tryParse(shift?.shiftStartedAt ?? '') ??
                          DateTime.now();

                      final amount = isCashier
                          ? shift?.grossSalesAmount ??
                                summary?.today.grossSalesAmount ??
                                0
                          : summary?.today.grossSalesAmount ?? 0;

                      final salesCount = isCashier
                          ? shift?.salesCount ?? summary?.today.salesCount ?? 0
                          : summary?.today.salesCount ?? 0;

                      final labelName = isCashier
                          ? cashierName
                          : context.tr.posTodaySales;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDims.s4,
                          AppDims.s3,
                          AppDims.s4,
                          AppDims.s1,
                        ),
                        child: CashierShiftCard(
                          cashierName: labelName,
                          shiftStart: shiftStart,
                          amount: amount,
                          salesCount: salesCount,
                          sparkline: summary?.sparklineAmounts.isEmpty == false
                              ? summary!.sparklineAmounts
                              : const [0, 0],
                          currencyLabel: summary?.currency ?? 'SDG',
                        ),
                      );
                    },
                  ),
                  PosSearchSection(searchCtrl: _searchCtrl),
                  const CategoryBar(),
                  Expanded(
                    child: BlocBuilder<ProductBloc, ProductState>(
                      buildWhen: (prev, curr) =>
                          prev.productStatus != curr.productStatus ||
                          prev.products != curr.products ||
                          prev.categories != curr.categories,
                      builder: (context, productState) {
                        if (productState.productStatus ==
                                ProductStatus.loading ||
                            productState.productStatus ==
                                ProductStatus.initial) {
                          return const ProductsLoadingGrid();
                        }

                        if (productState.productStatus ==
                            ProductStatus.failure) {
                          return ProductErrorView(
                            message: productState.responseError,
                          );
                        }

                        return BlocBuilder<PosBloc, PosState>(
                          buildWhen: (prev, curr) =>
                              prev.searchQuery != curr.searchQuery ||
                              prev.selectedCategoryId !=
                                  curr.selectedCategoryId,
                          builder: (context, posState) {
                            final products = _filterProducts(
                              productState.products,
                              posState,
                            );
                            if (products.isEmpty) {
                              return ProductsEmpty(query: posState.searchQuery);
                            }
                            return LayoutBuilder(
                              builder: (ctx, constraints) {
                                final cols = ctx.gridColumnsFor(
                                  constraints.maxWidth,
                                  tile: 176,
                                );
                                return ProductGrid(
                                  products: products,
                                  crossAxisCount: cols,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );

              // Desktop: top bar + 3-column layout of floating cards on the
              // background canvas — same composition as the inventory and
              // sales history desktop screens.
              // AppTextStyles base sizes are mobile-design sizes; on desktop
              // they read oversized, so the whole subtree is scaled down.
              if (context.isDesktop) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(0.85)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DesktopPosTopBar(
                        onRefresh: _desktopRefresh,
                        onShopSelected: (shopId, shopName) {
                          context.read<PosBloc>().add(
                            PosShopSelected(shopId: shopId, shopName: shopName),
                          );
                          context.read<DashboardSummaryBloc>().add(
                            OnDashboardSummaryShopChanged(shopId: shopId),
                          );
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDims.s5,
                            AppDims.s4,
                            AppDims.s5,
                            AppDims.s5,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const DesktopCategorySidebar(),
                              const SizedBox(width: AppDims.s4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PosSearchSection(searchCtrl: _searchCtrl),
                                    Expanded(
                                      child:
                                          BlocBuilder<
                                            ProductBloc,
                                            ProductState
                                          >(
                                            buildWhen: (prev, curr) =>
                                                prev.productStatus !=
                                                    curr.productStatus ||
                                                prev.products !=
                                                    curr.products ||
                                                prev.categories !=
                                                    curr.categories,
                                            builder: (context, productState) {
                                              if (productState.productStatus ==
                                                      ProductStatus.loading ||
                                                  productState.productStatus ==
                                                      ProductStatus.initial) {
                                                return const ProductsLoadingGrid();
                                              }
                                              if (productState.productStatus ==
                                                  ProductStatus.failure) {
                                                return ProductErrorView(
                                                  message: productState
                                                      .responseError,
                                                );
                                              }
                                              return BlocBuilder<
                                                PosBloc,
                                                PosState
                                              >(
                                                buildWhen: (prev, curr) =>
                                                    prev.searchQuery !=
                                                        curr.searchQuery ||
                                                    prev.selectedCategoryId !=
                                                        curr.selectedCategoryId,
                                                builder: (context, posState) {
                                                  final products =
                                                      _filterProducts(
                                                        productState.products,
                                                        posState,
                                                      );
                                                  if (products.isEmpty) {
                                                    return ProductsEmpty(
                                                      query:
                                                          posState.searchQuery,
                                                    );
                                                  }
                                                  return LayoutBuilder(
                                                    builder:
                                                        (ctx, constraints) {
                                                          final cols = ctx
                                                              .gridColumnsFor(
                                                                constraints
                                                                    .maxWidth,
                                                                tile: 160,
                                                              );
                                                          return ProductGrid(
                                                            products: products,
                                                            crossAxisCount:
                                                                cols,
                                                            desktop: true,
                                                          );
                                                        },
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppDims.s4),
                              SizedBox(
                                width: 380,
                                child: DesktopCartPanel(
                                  onCheckout: _handleCheckout,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Mobile: existing RefreshIndicator layout (unchanged)
              return RefreshIndicator(
                color: context.appColors.primary,
                notificationPredicate: (_) => !posState.cartExpanded,
                onRefresh: posState.cartExpanded
                    ? () async {}
                    : () async {
                        context.read<ProductBloc>().add(
                          const OnProductInitial(force: true),
                        );
                        context.read<BusinessBloc>().add(OnBusinessInitial());
                        _searchCtrl.clear();
                        context.read<PosBloc>().add(const PosSearchChanged(''));
                        context.read<PosBloc>().add(
                          const PosCategoryChanged(null),
                        );
                        await Future<void>.delayed(
                          const Duration(milliseconds: 450),
                        );

                        final shopId =
                            _autoSelectShop() ??
                            context.read<PosBloc>().state.selectedShopId;

                        context.read<DashboardSummaryBloc>().add(
                          OnDashboardSummaryRefreshRequested(
                            shopId: shopId,
                            topSellersLimit: 10,
                          ),
                        );
                      },
                child: Column(
                  children: [
                    Expanded(child: productPane),
                    BlocBuilder<PosBloc, PosState>(
                      buildWhen: (prev, curr) => prev.isEmpty != curr.isEmpty,
                      builder: (context, state) =>
                          SizedBox(height: state.isEmpty ? 0 : 88),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<ProductData> _filterProducts(
    List<ProductData> products,
    PosState state,
  ) {
    final query = state.searchQuery.trim().toLowerCase();
    return products.where((product) {
      if (!(product.isActive ?? true)) return false;
      final matchesCategory =
          state.selectedCategoryId == null ||
          product.category == state.selectedCategoryId;
      final matchesSearch =
          query.isEmpty ||
          (product.name?.toLowerCase().contains(query) ?? false) ||
          (product.sku?.toLowerCase().contains(query) ?? false) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }
}

String money(double value) {
  final formatted = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return formatted.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
