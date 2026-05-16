import 'package:amana_pos/features/inventory/presentation/bloc/stock_levels_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showLowStockSheet(BuildContext context, {VoidCallback? onReceive}) {
  context.read<StockLevelsBloc>().add(const OnStockLevelsStarted(lowStockOnly: true));
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<StockLevelsBloc>(),
      child: _LowStockSheet(onReceive: onReceive),
    ),
  );
}

class _LowStockSheet extends StatelessWidget {
  final VoidCallback? onReceive;
  const _LowStockSheet({this.onReceive});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCD34D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Color(0xFFFCD34D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDims.s3),
                    Text(
                      'Low Stock',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(SolarIconsOutline.closeCircle,
                          color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<StockLevelsBloc, StockLevelsState>(
                  builder: (context, state) {
                    if (state.status == StockLevelsStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = state.items
                        .where((s) =>
                            (s.isLowStock ?? false) ||
                            (s.isOutOfStock ?? false))
                        .toList();
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 48, color: Color(0xFF5EEAD4)),
                            const SizedBox(height: 12),
                            Text(
                              'All stock levels healthy!',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppDims.s4),
                      itemCount: items.length,
                      separatorBuilder: (_, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isOut = item.isOutOfStock ?? false;
                        final badgeColor = isOut
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFFCD34D);
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppDims.s2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: badgeColor.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  isOut ? 'Out' : 'Low',
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bs300(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity ?? '0'}',
                                      style: AppTextStyles.bs200(context)
                                          .copyWith(
                                              color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onReceive?.call();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: goldDeep,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                                child: const Text(
                                  'Receive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
