import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StockList extends StatelessWidget {
  final List<StockData> items;
  final bool isLoadingMore;

  const StockList({super.key,
    required this.items,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s4,
            AppDims.s4,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
            itemBuilder: (_, i) {
              return StockCard(item: items[i])
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 40 + (i % 8) * 25),
                duration: 240.ms,
              )
                  .slideY(
                begin: 0.04,
                end: 0,
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
        if (isLoadingMore)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.appColors.primary,
                ),
              ),
            ),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
