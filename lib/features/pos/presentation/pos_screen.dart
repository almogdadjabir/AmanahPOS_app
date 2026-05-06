import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/cart/presentation/cart_sheet.dart';
import 'package:amana_pos/features/cart/presentation/products_empty.dart';
import 'package:amana_pos/features/cart/presentation/products_loading_grid.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/category_bar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_search_section.dart';
import 'package:amana_pos/features/pos/presentation/widgets/product_grid.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
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
    if (businessState.businessList == null || businessState.businessList!.isEmpty) {
      context.read<BusinessBloc>().add(OnBusinessInitial());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _defaultShopId() async {
    final fromBusinessBloc = _shopFromBusinessList(
      context.read<BusinessBloc>().state.businessList,
    );

    if (fromBusinessBloc != null) return fromBusinessBloc;

    final fromAuthBloc = _shopFromBusiness(
      context.read<AuthBloc>().state.defaultBusiness,
    );

    if (fromAuthBloc != null) return fromAuthBloc;

    try {
      final cache = getIt<OfflineLocalCache>();

      final cachedShops = await cache.getShops();
      if (cachedShops.isNotEmpty) {
        final shopId = cachedShops.first.id;
        if (shopId != null && shopId.isNotEmpty) return shopId;
      }

      final cachedBusinesses = await cache.getBusinesses();
      final fromCachedBusinesses = _shopFromBusinessList(cachedBusinesses);

      if (fromCachedBusinesses != null) return fromCachedBusinesses;
    } catch (_) {
      // Do not block checkout UI if cache read fails.
    }

    return null;
  }

  String? _shopFromBusinessList(List<BusinessData>? businesses) {
    if (businesses == null || businesses.isEmpty) return null;

    for (final business in businesses) {
      final shopId = _shopFromBusiness(business);
      if (shopId != null) return shopId;
    }

    return null;
  }

  String? _shopFromBusiness(BusinessData? business) {
    if (business == null) return null;

    final shops = business.shops;
    if (shops == null || shops.isEmpty) return null;

    for (final shop in shops) {
      final shopId = shop.id;
      final isActive = shop.isActive ?? true;

      if (shopId != null && shopId.isNotEmpty && isActive) {
        return shopId;
      }
    }

    return null;
  }

  Future<void> _handleCheckout() async {
    if (_checkoutResolvingShop) return;

    _checkoutResolvingShop = true;

    try {
      final shopId = await _defaultShopId();

      if (!mounted) return;

      if (shopId == null || shopId.isEmpty) {
        GlobalSnackBar.show(
          message: 'No shop found on this device. Please connect once to refresh your business data.',
          isError: true,
          isAutoDismiss: false,
        );
        return;
      }

      context.read<PosBloc>().add(
        PosCheckoutSubmitted(shopId: shopId),
      );
    } finally {
      _checkoutResolvingShop = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == PosSubmitStatus.success) {
          context.read<ProductBloc>().add(
            OnProductsSoldLocally(
              soldQuantities: state.lastSoldQuantities,
            ),
          );

          final message = state.submitError?.isNotEmpty == true
              ? state.submitError!
              : 'Sale completed successfully';

          GlobalSnackBar.show(
            message: message,
            isInfo: true,
          );

          context.read<PosBloc>().add(const PosAcknowledgeSubmit());
        }

        if (state.submitStatus == PosSubmitStatus.failure) {
          final raw = state.submitError ?? 'Failed to complete sale';

          final message = raw.contains('BANKAK_ACCOUNT_REQUIRED')
              ? 'Please add your Bankak account number in Settings before accepting Bankak payments.'
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
                  context.read<ProductBloc>().add(const OnProductInitial());
                  context.read<BusinessBloc>().add(OnBusinessInitial());

                  _searchCtrl.clear();
                  context.read<PosBloc>().add(const PosSearchChanged(''));
                  context.read<PosBloc>().add(const PosCategoryChanged(null));

                  await Future<void>.delayed(
                    const Duration(milliseconds: 450),
                  );
                },
                child: Stack(
                  children: [
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
                              if (productState.productStatus == ProductStatus.loading ||
                                  productState.productStatus == ProductStatus.initial) {
                                return const ProductsLoadingGrid();
                              }

                              if (productState.productStatus == ProductStatus.failure) {
                                return ProductErrorView(
                                  message: productState.responseError,
                                );
                              }

                              return BlocBuilder<PosBloc, PosState>(
                                buildWhen: (prev, curr) =>
                                prev.searchQuery != curr.searchQuery ||
                                    prev.selectedCategoryId != curr.selectedCategoryId,
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

                                  return ProductGrid(products: products);
                                },
                              );
                            },
                          ),
                        ),
                        BlocBuilder<PosBloc, PosState>(
                          buildWhen: (prev, curr) => prev.isEmpty != curr.isEmpty,
                          builder: (context, state) {
                            return SizedBox(height: state.isEmpty ? 0 : 88);
                          },
                        ),
                      ],
                    ),
                    CartSheet(
                      onCheckout: _handleCheckout,
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
      final active = product.isActive ?? true;
      if (!active) return false;

      final matchesCategory = state.selectedCategoryId == null ||
          product.category == state.selectedCategoryId;

      final matchesSearch = query.isEmpty ||
          (product.name?.toLowerCase().contains(query) ?? false) ||
          (product.sku?.toLowerCase().contains(query) ?? false) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);

      return matchesCategory && matchesSearch;
    }).toList();
  }
}

String money(double value) {
  return value.toStringAsFixed(2);
}