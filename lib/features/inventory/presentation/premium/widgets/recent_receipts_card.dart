import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class RecentReceiptsCard extends StatelessWidget {
  final List<InboundTransactionData> recentInbound;
  final bool isLoading;
  final VoidCallback? onTap;

  const RecentReceiptsCard({
    super.key,
    required this.recentInbound,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final top2 = recentInbound.take(2).toList();

    return BentoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            title: 'Recent Receipts',
            icon: SolarIconsOutline.documentText,
            accent: Color(0xFF93C5FD),
          ),
          const SizedBox(height: AppDims.s3),
          if (isLoading) ...[
            const ShimmerBox(height: 44),
            const SizedBox(height: AppDims.s2),
            const ShimmerBox(height: 44),
          ] else if (top2.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDims.s3),
                child: Text(
                  'No recent receipts',
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...top2.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: AppDims.s2),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD)
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        SolarIconsOutline.documentText,
                        color: Color(0xFF93C5FD),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppDims.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.reference ?? 'Unknown ref',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            tx.vendorName ?? tx.shopName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tx.totalQuantity != null
                          ? '${tx.totalQuantity} units'
                          : '${tx.itemCount} items',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
