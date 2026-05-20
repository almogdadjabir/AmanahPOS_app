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
            const Expanded(
              child: Center(
                child: ShimmerBox(height: 80),
              ),
            )
          else if (top3.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No vendor data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            CompactCardScrollArea(
              showHint: top3.length > 4,
              child: Column(
                children: List.generate(top3.length, (i) {
                  final v = top3[i];
                  final rank = i < medals.length ? medals[i] : '#${i + 1}';

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == top3.length - 1 ? 0 : AppDims.s2,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            rank,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: i < 3 ? 14 : 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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
                        const SizedBox(width: 6),
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
              ),
            ),
        ],
      ),
    );
  }
}
