import 'package:amana_pos/features/inventory/data/models/responses/vendor_summary_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class VendorBoardCard extends StatelessWidget {
  final VendorSummaryData? vendorSummary;
  final bool isLoading;
  final VoidCallback? onTap;

  const VendorBoardCard({
    super.key,
    this.vendorSummary,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final top3 = (vendorSummary?.vendors ?? []).take(3).toList();
    const medals = ['🥇', '🥈', '🥉'];

    return BentoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            title: 'Vendor Board',
            icon: SolarIconsOutline.shop,
            accent: goldDeep,
          ),
          const SizedBox(height: AppDims.s3),
          if (isLoading)
            const ShimmerBox(height: 80)
          else if (top3.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDims.s2),
                child: Text(
                  'No vendor data',
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...List.generate(top3.length, (i) {
              final v = top3[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDims.s2),
                child: Row(
                  children: [
                    Text(medals[i],
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        v.vendorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${v.transactionsCount}x',
                      style: const TextStyle(
                        color: goldDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
