import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/cart/presentation/products_empty.dart';
import 'package:amana_pos/features/cart/presentation/products_loading_grid.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/category_bar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_sales_caption.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_search_section.dart';
import 'package:amana_pos/features/pos/presentation/widgets/product_grid.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
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
  bool  _checkoutResolvingShop = false;

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
      _autoSelectShop();
      _loadDashboardSummary();
    });
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


  String? _autoSelectShop() {
    if (!mounted) return null;

    final posState = context.read<PosBloc>().state;
    if (posState.selectedShopId != null && posState.selectedShopId!.isNotEmpty) {
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
      PosShopSelected(
        shopId: shopId,
        shopName: first.name ?? 'Shop',
      ),
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
            message:
            'Bankak account is not set up. Go to Settings and add your account number first.',
            isError:       true,
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
              ? 'You are not assigned to a shop. Contact your manager.'
              : 'No shop found. Please refresh and try again.';
          GlobalSnackBar.show(
            message: message,
            isError: true,
            isAutoDismiss: false,
          );
          return;
        }

        context.read<PosBloc>().add(PosShopSelected(
          shopId: fallback,
          shopName: 'Shop',
        ));
        context
            .read<PosBloc>()
            .add(PosCheckoutSubmitted(shopId: fallback));
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
    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) =>
      prev.submitStatus != curr.submitStatus ||
          prev.submitError != curr.submitError,
      listener: (context, state) {
        if (state.submitStatus == PosSubmitStatus.idle &&
            state.submitError?.isNotEmpty == true) {
          GlobalSnackBar.show(
            message: state.submitError!,
            isError: true,
          );
          context.read<PosBloc>().add(const PosAcknowledgeSubmit());
          return;
        }

        if (state.submitStatus == PosSubmitStatus.success) {
          context.read<ProductBloc>().add(
            OnProductsSoldLocally(
              soldQuantities: state.lastSoldQuantities,
            ),
          );

          final message = state.submitError?.isNotEmpty == true
              ? state.submitError!
              : 'Sale completed successfully';

          GlobalSnackBar.show(message: message, isInfo: true);
          context.read<PosBloc>().add(const PosAcknowledgeSubmit());

          final shopId = _autoSelectShop() ?? context.read<PosBloc>().state.selectedShopId;

          context.read<DashboardSummaryBloc>().add(
            OnDashboardSummaryRefreshRequested(
              shopId: shopId,
              topSellersLimit: 10,
            ),
          );
        }

        if (state.submitStatus == PosSubmitStatus.failure) {
          final raw = state.submitError ?? 'Failed to complete sale';
          final message = raw.contains('BANKAK_ACCOUNT_REQUIRED')
              ? 'Please add your Bankak account number in Settings.'
              : raw.contains('SHOP_MISMATCH')
              ? 'You are not assigned to this shop. Contact your manager.'
              : raw;

          GlobalSnackBar.show(
            message: message,
            isError: true,
            isAutoDismiss: false,
          );
          context.read<PosBloc>().add(const PosAcknowledgeSubmit());
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<PosBloc, PosState>(
            buildWhen: (prev, curr) => prev.cartExpanded != curr.cartExpanded,
            builder: (context, posState) {
              return RefreshIndicator(
                color: context.appColors.primary,
                notificationPredicate: (_) => !posState.cartExpanded,
                onRefresh: posState.cartExpanded
                    ? () async {}
                    : () async {
                  context
                      .read<ProductBloc>()
                      .add(const OnProductInitial(force: true));
                  context
                      .read<BusinessBloc>()
                      .add(OnBusinessInitial());
                  _searchCtrl.clear();
                  context
                      .read<PosBloc>()
                      .add(const PosSearchChanged(''));
                  context
                      .read<PosBloc>()
                      .add(const PosCategoryChanged(null));
                  await Future<void>.delayed(
                      const Duration(milliseconds: 450));

                  final shopId = _autoSelectShop() ?? context.read<PosBloc>().state.selectedShopId;

                  context.read<DashboardSummaryBloc>().add(
                    OnDashboardSummaryRefreshRequested(
                      shopId: shopId,
                      topSellersLimit: 10,
                    ),
                  );
                },
                child: Column(
                  children: [
                    BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
                      buildWhen: (prev, curr) =>
                      prev.status != curr.status || prev.summary != curr.summary,
                      builder: (context, state) {
                        final authState = context.read<AuthBloc>().state;
                        final summary = state.summary;
                        final shift = summary?.shift;

                        final isCashier = authState.permissions.isCashier;

                        final cashierName = shift?.cashierName?.trim().isNotEmpty == true
                            ? shift!.cashierName!
                            : authState.profile?.fullName ?? 'Cashier';

                        final shiftStart = DateTime.tryParse(shift?.shiftStartedAt ?? '') ??
                            DateTime.now();

                        final amount = isCashier
                            ? shift?.grossSalesAmount ?? summary?.today.grossSalesAmount ?? 0
                            : summary?.today.grossSalesAmount ?? 0;

                        final salesCount = isCashier
                            ? shift?.salesCount ?? summary?.today.salesCount ?? 0
                            : summary?.today.salesCount ?? 0;

                        final labelName = isCashier ? cashierName : 'Today sales';

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
                            prev.products    != curr.products ||
                            prev.categories  != curr.categories,
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
                            prev.searchQuery        != curr.searchQuery ||
                                prev.selectedCategoryId !=
                                    curr.selectedCategoryId,
                            builder: (context, posState) {
                              final products = _filterProducts(
                                  productState.products, posState);
                              if (products.isEmpty) {
                                return ProductsEmpty(
                                    query: posState.searchQuery);
                              }
                              return ProductGrid(products: products);
                            },
                          );
                        },
                      ),
                    ),
                    BlocBuilder<PosBloc, PosState>(
                      buildWhen: (prev, curr) =>
                      prev.isEmpty != curr.isEmpty,
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
      List<ProductData> products, PosState state) {
    final query = state.searchQuery.trim().toLowerCase();
    return products.where((product) {
      if (!(product.isActive ?? true)) return false;
      final matchesCategory = state.selectedCategoryId == null ||
          product.category == state.selectedCategoryId;
      final matchesSearch = query.isEmpty ||
          (product.name?.toLowerCase().contains(query)    ?? false) ||
          (product.sku?.toLowerCase().contains(query)     ?? false) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }
}

class _ShopSwitcherBar extends StatelessWidget {
  final List<ShopData> activeShops;

  const _ShopSwitcherBar({required this.activeShops});

  @override
  Widget build(BuildContext context) {
    final permissions = context.read<AuthBloc>().state.permissions;

    // Cashiers and single-shop owners: render nothing
    if (permissions.isCashier || activeShops.length < 2) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PosBloc, PosState>(
      buildWhen: (prev, curr) => prev.selectedShopId != curr.selectedShopId,
      builder: (context, posState) {
        final colors       = context.appColors;
        final selectedName = posState.selectedShopName ?? 'Select shop';

        return Container(
          width:   double.infinity,
          padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s2, AppDims.s4, AppDims.s1),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeShops.map((shop) {
                final isSelected = shop.id == posState.selectedShopId;

                return Padding(
                  padding: const EdgeInsets.only(right: AppDims.s2),
                  child: GestureDetector(
                    onTap: isSelected
                        ? null
                        : () {
                      context.read<PosBloc>().add(
                        PosShopSelected(
                          shopId: shop.id!,
                          shopName: shop.name ?? 'Shop',
                        ),
                      );

                      context.read<DashboardSummaryBloc>().add(
                        OnDashboardSummaryShopChanged(shopId: shop.id!),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDims.s3, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary
                            : colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? colors.primary
                              : colors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size:  14,
                            color: isSelected
                                ? Colors.white
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            shop.name ?? 'Shop',
                            style: AppTextStyles.bs200(context).copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

String money(double value) => value.toStringAsFixed(2);