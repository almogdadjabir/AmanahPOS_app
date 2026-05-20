import 'package:amana_pos/features/inventory/presentation/bloc/premium_inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/expiry_timeline_card.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/health_ring_card.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/inbound_velocity_card.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/quick_actions_card.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/recent_receipts_card.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/restock_queue_card.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/vendor_board_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BentoGrid extends StatelessWidget {
  final VoidCallback? onOpenStockLevels;
  final VoidCallback? onOpenInbound;
  final VoidCallback? onOpenLowStock;
  final VoidCallback? onOpenExpiry;
  final VoidCallback? onOpenVendors;
  final VoidCallback? onOpenInboundHistory;

  const BentoGrid({
    super.key,
    this.onOpenStockLevels,
    this.onOpenInbound,
    this.onOpenLowStock,
    this.onOpenExpiry,
    this.onOpenVendors,
    this.onOpenInboundHistory,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<PremiumInventoryBloc, PremiumInventoryState>(
        builder: (context, state) {
          final isLoading = state.status == PremiumInventoryStatus.loading;
          return Padding(
            padding: const EdgeInsets.all(AppDims.s4),
            child: Column(
              children: [
                // Row 1: Health Ring + Inbound Velocity — IntrinsicHeight keeps both cards equal
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: HealthRingCard(
                          summary: state.premiumSummary,
                          isLoading: isLoading,
                          onTap: onOpenStockLevels,
                        ),
                      ),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        child: InboundVelocityCard(
                          recentInbound: state.recentInbound,
                          isLoading: isLoading,
                          // onTap: onOpenInbound,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDims.s3),
                // Row 2: Restock Queue (full width)
                RestockQueueCard(
                  lowStockItems: state.lowStockItems,
                  isLoading: isLoading,
                  onTap: onOpenLowStock,
                ),
                const SizedBox(height: AppDims.s3),
                // Row 3: Expiry Timeline + Vendor Board (1 col each)

                SizedBox(
                  height: 168,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ExpiryTimelineCard(
                          items: state.expiryPreview,
                          isLoading: isLoading,
                          onTap: onOpenExpiry,
                        ),
                      ),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        child: VendorBoardCard(
                          vendorSummary: state.vendorSummary,
                          isLoading: isLoading,
                          onTap: onOpenVendors,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDims.s3),
                // Row 4: Recent Receipts (full width)
                RecentReceiptsCard(
                  recentInbound: state.recentInbound,
                  isLoading: isLoading,
                  onTap: onOpenInboundHistory,
                ),
                const SizedBox(height: AppDims.s3),
                // Row 5: Quick Actions (full width)
                QuickActionsCard(
                  onReceive: onOpenInbound,
                  onStockLevels: onOpenStockLevels,
                  onVendors: onOpenVendors,
                  onExpiry: onOpenExpiry,
                ),
                SizedBox(
                  height: MediaQuery.viewPaddingOf(context).bottom,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
