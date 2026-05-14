import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StockList extends StatelessWidget {
  final List<StockData> items;
  final bool isLoadingMore;

  const StockList({
    super.key,
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
            itemBuilder: (_, index) {
              final item = items[index];

              return StockCard(item: item)
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 24 + (index % 6) * 18),
                duration: 220.ms,
              )
                  .slideY(
                begin: 0.025,
                end: 0,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),

        if (isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDims.s5),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: context.appColors.primary,
                  ),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}