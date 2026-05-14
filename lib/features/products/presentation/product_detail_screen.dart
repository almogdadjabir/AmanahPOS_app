import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_actions_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_detail_app_bar_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_stock_section_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_summary_card_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductData product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final bool _showStock;

  @override
  void initState() {
    super.initState();
    _showStock =
        !context.read<AuthBloc>().state.permissions.isRestaurant;

    final inv = context.read<InventoryBloc>().state;
    if (inv.status == InventoryStatus.initial && inv.stockList.isEmpty) {
      context.read<InventoryBloc>().add(const OnInventoryInitial());
    }

    final expiry = context.read<ExpiryBloc>().state;
    if (expiry.status == ExpiryStatus.initial && expiry.alerts.isEmpty) {
      context.read<ExpiryBloc>().add(const OnExpiryAlertsInitial());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductBloc, ProductState, ProductData?>(
      selector: (state) =>
          state.products.where((p) => p.id == widget.product.id).firstOrNull,
      builder: (context, latestProduct) {
        final current = latestProduct ?? widget.product;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ProductDetailAppBarView(product: current),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                sliver: SliverToBoxAdapter(
                  child: ProductSummaryCardView(
                    product: current,
                    showStock: _showStock,
                  )
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                sliver: SliverToBoxAdapter(
                  child: ProductActionsView(
                    product: current,
                    showStock: _showStock,
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                ),
              ),

              if (_showStock) ...[

                BlocBuilder<InventoryBloc, InventoryState>(
                  buildWhen: (prev, curr) =>
                      prev.stockList != curr.stockList ||
                      prev.status != curr.status,
                  builder: (context, invState) {
                    final productStock =
                        _filterStock(invState.stockList, current);
                    final expiredCount = productStock
                        .where((s) => s.isExpiredSafe)
                        .length;
                    final expiringSoonCount = productStock
                        .where((s) => s.isExpiringSoon)
                        .length;

                    if (expiredCount == 0 && expiringSoonCount == 0) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppDims.s4, AppDims.s5, AppDims.s4, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ExpiryBanner(
                          expiredCount: expiredCount,
                          expiringSoonCount: expiringSoonCount,
                        ),
                      ),
                    );
                  },
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDims.s4, AppDims.s5, AppDims.s4, AppDims.s2),
                  sliver: SliverToBoxAdapter(
                    child: WorkspaceSectionHeader(title: 'Stock by Shop')
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

  /// Filter a flat stock list down to rows belonging to [product].
  static List<StockData> _filterStock(
      List<StockData> list, ProductData product) {
    final id = product.id;
    if (id != null) {
      return list.where((s) => s.product == id).toList();
    }
    final name = product.name?.trim().toLowerCase();
    if (name == null || name.isEmpty) return const [];
    return list
        .where((s) => s.productName?.trim().toLowerCase() == name)
        .toList();
  }
}

// ── Expiry summary banner ─────────────────────────────────────────────────────
// Styled like _InfoTile from ProductSummaryCardView: same rMd radius,
// same color.withValues(alpha:0.08) background, icon-on-left layout.

class _ExpiryBanner extends StatelessWidget {
  final int expiredCount;
  final int expiringSoonCount;

  const _ExpiryBanner({
    required this.expiredCount,
    required this.expiringSoonCount,
  });

  @override
  Widget build(BuildContext context) {
    // Colour priority: red if anything is expired, else orange.
    final hasExpired = expiredCount > 0;
    const expiredColor = Color(0xFFDC2626);
    const expiringSoonColor = Color(0xFFEA580C);
    final color = hasExpired ? expiredColor : expiringSoonColor;

    final parts = <String>[];
    if (expiredCount > 0) {
      parts.add('$expiredCount batch${expiredCount == 1 ? '' : 'es'} expired');
    }
    if (expiringSoonCount > 0) {
      parts.add(
          '$expiringSoonCount expiring soon');
    }

    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pushNamed(RouteStrings.expiryAlertsScreen),
      child: Container(
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDims.rMd),
        ),
        child: Row(
          children: [
            Icon(
              hasExpired
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                parts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
