import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/cart/presentation/cart_sheet.dart';
import 'package:amana_pos/features/cart/presentation/products_empty.dart';
import 'package:amana_pos/features/cart/presentation/products_error.dart';
import 'package:amana_pos/features/cart/presentation/products_loading_grid.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/category_bar.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_search_section.dart';
import 'package:amana_pos/features/pos/presentation/widgets/product_grid.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
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

  String? _defaultShopId(BuildContext context) {
    final businesses = context.read<BusinessBloc>().state.businessList;
    if (businesses == null || businesses.isEmpty) return null;

    final shops = businesses.first.shops;
    if (shops == null || shops.isEmpty) return null;

    return shops.first.id;
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

          context.read<ProductBloc>().add(const OnProductInitial());

          GlobalSnackBar.show(
            message: 'Sale completed successfully',
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
        backgroundColor: context.appColors.background,
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
                                  // onRetry: () {
                                  //   context.read<ProductBloc>().add(
                                  //     const OnProductInitial(),
                                  //   );
                                  // },
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
                      onCheckout: () {
                        final shopId = _defaultShopId(context);

                        if (shopId == null) {
                          GlobalSnackBar.show(
                            message: 'Please create/select a shop first',
                            isError: true,
                          );
                          return;
                        }

                        context.read<PosBloc>().add(
                          PosCheckoutSubmitted(shopId: shopId),
                        );
                      },
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