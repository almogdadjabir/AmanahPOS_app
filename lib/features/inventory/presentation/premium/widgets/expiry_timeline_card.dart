import 'package:amana_pos/features/inventory/data/models/responses/expiry_report_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ExpiryTimelineCard extends StatelessWidget {
  final List<ExpiryReportItem> items;
  final bool isLoading;
  final VoidCallback? onTap;

  const ExpiryTimelineCard({
    super.key,
    required this.items,
    required this.isLoading,
    this.onTap,
  });

  Color _chipColor(ExpiryReportItem item) {
    if (item.isExpired || item.daysRemaining <= 0) {
      return const Color(0xFFFCA5A5);
    }
    if (item.daysRemaining <= 5) return const Color(0xFFFCA5A5);
    if (item.daysRemaining <= 14) return const Color(0xFFFCD34D);
    return const Color(0xFF5EEAD4);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final top3 = items.take(3).toList();

    return BentoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            title: 'Expiry Timeline',
            icon: SolarIconsOutline.calendar,
            accent: Color(0xFFFCA5A5),
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
                  'No expiring items',
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
                children: List.generate(top3.length, (index) {
                  final item = top3[index];
                  final chipColor = _chipColor(item);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == top3.length - 1 ? 0 : AppDims.s2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: chipColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            item.isExpired ? 'Expired' : '${item.daysRemaining}d',
                            style: TextStyle(
                              color: chipColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
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
