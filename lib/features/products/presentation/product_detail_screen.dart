import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/localization/app_localizations_product_extensions.dart';
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
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductData product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final bool _showStock;

  @override
  void initState() {
    super.initState();

    _showStock = !context.read<AuthBloc>().state.permissions.isRestaurant;

    final inventoryBloc = context.read<InventoryBloc>();
    final inventoryState = inventoryBloc.state;

    if (inventoryState.status == InventoryStatus.initial &&
        inventoryState.stockList.isEmpty && !context
        .read<AuthBloc>()
        .state
        .permissions
        .isRestaurant) {
      inventoryBloc.add(const OnInventoryInitial());
    }

    final expiryBloc = context.read<ExpiryBloc>();
    final expiryState = expiryBloc.state;

    if (expiryState.status == ExpiryStatus.initial &&
        expiryState.alerts.isEmpty && !context
        .read<AuthBloc>()
        .state
        .permissions
        .isRestaurant) {
      expiryBloc.add(const OnExpiryAlertsInitial());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductBloc, ProductState, ProductData?>(
      selector: (state) {
        for (final product in state.products) {
          if (product.id == widget.product.id) return product;
        }

        return null;
      },
      builder: (context, latestProduct) {
        final current = latestProduct ?? widget.product;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ProductDetailAppBarView(product: current),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ProductSummaryCardView(
                    product: current,
                    showStock: _showStock,
                  )
                      .mAnimate()
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
                  child: ProductActionsView(
                    product: current,
                    showStock: _showStock,
                  )
                      .mAnimate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              if (_showStock) ...[
                BlocBuilder<InventoryBloc, InventoryState>(
                  buildWhen: (prev, curr) =>
                  prev.stockList != curr.stockList ||
                      prev.status != curr.status,
                  builder: (context, inventoryState) {
                    final expirySummary = _ProductExpirySummary.fromStockList(
                      inventoryState.stockList,
                      current,
                    );

                    if (!expirySummary.hasAlerts) {
                      return const SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        AppDims.s5,
                        AppDims.s4,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _ExpiryBanner(summary: expirySummary),
                      ),
                    );
                  },
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s5,
                    AppDims.s4,
                    AppDims.s2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: WorkspaceSectionHeader(
                      title: context.tr.stockByShop,
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
                    child: ProductStockSectionView(product: current),
                  ),
                ),
              ] else
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDims.s6),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductExpirySummary {
  final int expiredCount;
  final int expiringSoonCount;

  const _ProductExpirySummary({
    required this.expiredCount,
    required this.expiringSoonCount,
  });

  bool get hasExpired => expiredCount > 0;

  bool get hasAlerts => expiredCount > 0 || expiringSoonCount > 0;

  factory _ProductExpirySummary.fromStockList(
      List<StockData> stockList,
      ProductData product,
      ) {
    final productId = product.id;
    final productName = product.name?.trim().toLowerCase();

    var expiredCount = 0;
    var expiringSoonCount = 0;

    for (final stock in stockList) {
      final belongsToProduct = productId != null
          ? stock.product == productId
          : productName != null &&
          productName.isNotEmpty &&
          stock.productName?.trim().toLowerCase() == productName;

      if (!belongsToProduct) continue;

      if (stock.isExpiredSafe) {
        expiredCount++;
      }

      if (stock.isExpiringSoon) {
        expiringSoonCount++;
      }
    }

    return _ProductExpirySummary(
      expiredCount: expiredCount,
      expiringSoonCount: expiringSoonCount,
    );
  }
}

class _ExpiryBanner extends StatelessWidget {
  final _ProductExpirySummary summary;

  const _ExpiryBanner({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final hasExpired = summary.hasExpired;

    const expiredColor = Color(0xFFDC2626);
    const expiringSoonColor = Color(0xFFEA580C);

    final color = hasExpired ? expiredColor : expiringSoonColor;
    final message = _buildMessage(context, summary);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(RouteStrings.expiryAlertsScreen);
        },
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDims.s3),
            child: Row(
              children: [
                Icon(
                  hasExpired
                      ? SolarIconsOutline.dangerCircle
                      : SolarIconsOutline.dangerTriangle,
                  color: color,
                  size: 20,
                ),

                const SizedBox(width: AppDims.s2),

                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                DirectionalIcon(
                  icon: SolarIconsOutline.altArrowRight,
                  color: color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildMessage(
      BuildContext context,
      _ProductExpirySummary summary,
      ) {
    return context.tr.productExpirySummary(
      expiredCount: summary.expiredCount,
      expiringSoonCount: summary.expiringSoonCount,
    );
  }
}