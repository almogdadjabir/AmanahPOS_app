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

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductBloc, ProductState, ProductData?>(
      selector: (state) {
        return state.products.where((p) => p.id == product.id).firstOrNull;
      },
      builder: (context, latestProduct) {
        final currentProduct = latestProduct ?? product;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ProductDetailAppBarView(product: currentProduct),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ProductSummaryCardView(product: currentProduct)
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ProductActionsView(product: currentProduct)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s5,
                  AppDims.s4,
                  AppDims.s2,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Stock by Shop',
                    style: AppTextStyles.bs600(context).copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  AppDims.s6,
                ),
                sliver: SliverToBoxAdapter(
                  child: ProductStockSectionView(product: currentProduct),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}