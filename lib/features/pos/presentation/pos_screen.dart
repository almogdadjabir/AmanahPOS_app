import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/cart/presentation/products_empty.dart';
import 'package:amana_pos/features/cart/presentation/products_loading_grid.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/category_bar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_search_section.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_keypad_view.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_product_list.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
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
  bool _keypad = false;
  final _pages = PageController(initialPage: 1);
  final _progress = ValueNotifier<double>(1);

  void _syncProgress() {
    if (_pages.hasClients && _pages.position.haveDimensions) {
      _progress.value = (_pages.page ?? 1).clamp(0.0, 1.0);
    }
  }

  @override
  void initState() {
    super.initState();
    _pages.addListener(_syncProgress);

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
    context.read<PosBloc>().add(
      PosTaxConfigChanged(TaxConfig.fromBusiness(business)),
    );
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
    _pages.dispose();
    _progress.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
              prev.submitError != curr.submitError ||
              prev.removedUnavailable != curr.removedUnavailable,
          listener: (context, state) {
            if (state.removedUnavailable.isNotEmpty) {
              // Fix-wave I2: lines whose product was merged, discarded or
              // deleted were dropped (at checkout or while the cart was open).
              GlobalSnackBar.show(
                message: context.tr.posItemsUnavailable(
                  state.removedUnavailable.join(', '),
                ),
                isError: true,
                isAutoDismiss: false,
              );
              context.read<PosBloc>().add(const PosAcknowledgeSubmit());
              return;
            }
            if (state.submitStatus == PosSubmitStatus.idle &&
                state.submitError?.isNotEmpty == true) {
              GlobalSnackBar.show(message: state.submitError!, isError: true);
              context.read<PosBloc>().add(const PosAcknowledgeSubmit());
              return;
            }

            if (state.submitStatus == PosSubmitStatus.success) {
              context.read<ProductBloc>().add(
                OnProductsSoldLocally(soldQuantities: state.lastSoldQuantities),
              );

              final message = state.submitError?.isNotEmpty == true
                  ? state.submitError!
                  : context.tr.posSaleCompleted;
              GlobalSnackBar.show(message: message, isInfo: true);
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
              final productPane = Column(
                children: [
                  const _SellHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      AppDims.s3,
                    ),
                    child: AppSegmented<bool>(
                      segments: [
                        AppSegment(value: true, label: context.tr.posKeypad),
                        AppSegment(value: false, label: context.tr.posItems),
                      ],
                      selected: _keypad,
                      progress: _progress,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        _pages.animateToPage(
                          v ? 0 : 1,
                          duration: Motion.duration(AppDims.sheet),
                          curve: AppDims.sheetCurve,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) {
                        FocusScope.of(context).unfocus();
                        setState(() => _keypad = i == 0);
                      },
                      children: [
                        const PosKeypadView(),
                        Column(
                          children: [
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
                                        return ProductsEmpty(
                                          query: posState.searchQuery,
                                        );
                                      }
                                      return PosProductList(products: products);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              return RefreshIndicator(
                color: context.appColors.primary,
                notificationPredicate: (n) =>
                    n.metrics.axis == Axis.vertical && !posState.cartExpanded,
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

class _SellHeader extends StatelessWidget {
  const _SellHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        AppDims.s1,
        AppDims.s4,
        AppDims.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr.navSell,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.displayMedium!.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
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
