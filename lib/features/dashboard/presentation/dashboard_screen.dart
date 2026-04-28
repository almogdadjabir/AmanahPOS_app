import 'package:amana_pos/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:amana_pos/features/dashboard/data/models/mock_data.dart';
import 'package:amana_pos/features/dashboard/data/models/product.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:amana_pos/features/dashboard/presentation/widgets/cart_sheet.dart';
import 'package:amana_pos/features/dashboard/presentation/widgets/category_chips.dart';
import 'package:amana_pos/features/dashboard/presentation/widgets/product_card.dart';
import 'package:amana_pos/features/dashboard/presentation/widgets/products_empty.dart';
import 'package:amana_pos/features/dashboard/presentation/widgets/search_row.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // React to a successful charge: collapse cart + show snackbar.
        BlocListener<CartBloc, CartState>(
          listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == CartStatus.charged,
          listener: (context, cartState) {
            context
                .read<DashboardBloc>()
                .add(const SetCartExpandedEvent(expanded: false));

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: context.appColors.success,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Charged ${AppFormat.money(cartState.lastChargedTotal)} '
                      '${AppFormat.currency} · receipt sent',
                ),
              ),
            );

            context.read<CartBloc>().add(const AcknowledgeChargeEvent());
          },
        ),
      ],
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, dashState) {
          final products = MockData.filter(
            categoryId: dashState.activeCategory,
            query: dashState.searchQuery,
          );

          return Scaffold(
            backgroundColor: context.appColors.background,
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // ── Main column ──────────────────────────────────────
                  Column(
                    children: [
                      // Matches original: fromLTRB(s4=16, s3=12, s4=16, s2=8)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s2,
                        ),
                        child: SearchRow(
                          controller: _search,
                          onChanged: (v) => context
                              .read<DashboardBloc>()
                              .add(SetSearchQueryEvent(query: v)),
                        ),
                      ),
                      CategoryChips(
                        categories: MockData.categories,
                        activeId: dashState.activeCategory,
                        onPick: (id) => context
                            .read<DashboardBloc>()
                            .add(SetCategoryEvent(categoryId: id)),
                      ),
                      const SizedBox(height: AppDims.s2), // matches original
                      Expanded(
                        child: products.isEmpty
                            ? ProductsEmpty(query: dashState.searchQuery)
                            : _ProductGrid(products: products),
                      ),
                      // Reserve space for the peek bar when cart has items.
                      BlocBuilder<CartBloc, CartState>(
                        buildWhen: (prev, curr) =>
                        prev.isEmpty != curr.isEmpty,
                        builder: (_, cartState) => SizedBox(
                          height: cartState.isEmpty
                              ? 0
                              : AppDims.cartPeekHeight,
                        ),
                      ),
                    ],
                  ),

                  // ── Cart sheet ───────────────────────────────────────
                  CartSheet(
                    expanded: dashState.cartExpanded,
                    onExpandedChanged: (v) => context
                        .read<DashboardBloc>()
                        .add(SetCartExpandedEvent(expanded: v)),
                    onCharge: () =>
                        context.read<CartBloc>().add(const ChargeCartEvent()),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return GridView.builder(
          // Matches original: fromLTRB(s4=16, s2=8, s4=16, s4=16)
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4, AppDims.s2, AppDims.s4, AppDims.s4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppDims.s3,  // 12 — matches original
            crossAxisSpacing: AppDims.s3, // 12 — matches original
            childAspectRatio: 0.78,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            return ProductCard(
              product: p,
              qtyInCart: cartState.qtyOf(p.id),
              onAdd: () => context
                  .read<CartBloc>()
                  .add(AddProductEvent(product: p)),
            );
          },
        );
      },
    );
  }
}