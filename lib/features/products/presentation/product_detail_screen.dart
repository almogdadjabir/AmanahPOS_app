import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_actions_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_detail_app_bar_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_stock_section_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_summary_card_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductData product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Resolved once — never changes within this screen's lifetime.
    final showStock = !context.read<AuthBloc>().state.permissions.isRestaurant;

    return BlocSelector<ProductBloc, ProductState, ProductData?>(
      selector: (state) =>
      state.products.where((p) => p.id == product.id).firstOrNull,
      builder: (context, latestProduct) {
        final current = latestProduct ?? product;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar with image ───────────────────────────────────────
              ProductDetailAppBarView(product: current),

              // ── Summary card ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                sliver: SliverToBoxAdapter(
                  child: ProductSummaryCardView(
                    product:   current,
                    showStock: showStock,
                  )
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                ),
              ),

              // ── Action buttons ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                sliver: SliverToBoxAdapter(
                  child: ProductActionsView(
                    product:   current,
                    showStock: showStock,
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                ),
              ),

              // ── Stock by shop (shops only) ───────────────────────────────
              if (showStock) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDims.s4, AppDims.s5, AppDims.s4, AppDims.s2),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Stock by Shop',
                      style: AppTextStyles.bs600(context).copyWith(
                        color:      context.appColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDims.s4, 0, AppDims.s4, AppDims.s6),
                  sliver: SliverToBoxAdapter(
                    child: ProductStockSectionView(product: current),
                  ),
                ),
              ] else
              // Bottom breathing room for restaurants
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: AppDims.s6),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
            ],
          ),
        );
      },
    );
  }
}
