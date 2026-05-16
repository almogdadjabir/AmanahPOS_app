import 'package:amana_pos/features/inventory/presentation/bloc/premium_inventory_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/expiry_report_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/inbound_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/low_stock_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/stock_levels_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/vendors_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_grid.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/premium_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PremiumInventoryShell extends StatefulWidget {
  const PremiumInventoryShell({super.key});

  @override
  State<PremiumInventoryShell> createState() => _PremiumInventoryShellState();
}

class _PremiumInventoryShellState extends State<PremiumInventoryShell> {
  @override
  void initState() {
    super.initState();
    context.read<PremiumInventoryBloc>().add(const OnPremiumInventoryStarted());
  }

  Future<void> _refresh() async {
    context
        .read<PremiumInventoryBloc>()
        .add(const OnPremiumInventoryRefreshed());
  }

  void _openInbound() => showInboundSheet(context);
  void _openStockLevels() => showStockLevelsSheet(context);
  void _openLowStock() => showLowStockSheet(context);
  void _openExpiry() => showExpiryReportSheet(context);
  void _openVendors() => showVendorsSheet(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: RefreshIndicator(
        color: goldDeep,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<PremiumInventoryBloc, PremiumInventoryState>(
                buildWhen: (prev, curr) =>
                    prev.premiumSummary != curr.premiumSummary ||
                    prev.status != curr.status,
                builder: (context, state) {
                  return PremiumHeroHeader(
                    summary: state.premiumSummary,
                    isLoading:
                        state.status == PremiumInventoryStatus.loading,
                    onReceive: _openInbound,
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: BentoGrid(
                onOpenStockLevels: _openStockLevels,
                onOpenInbound: _openInbound,
                onOpenLowStock: _openLowStock,
                onOpenExpiry: _openExpiry,
                onOpenVendors: _openVendors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
