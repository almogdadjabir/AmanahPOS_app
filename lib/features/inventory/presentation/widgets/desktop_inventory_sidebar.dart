import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_action_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Right-hand column of the desktop inventory layout: quick actions, a
/// "Needs attention" triage panel, and (for shops) the expiry alerts list
/// brought in from the dedicated mobile screen so nothing requires leaving
/// the page.
class DesktopInventorySidebar extends StatelessWidget {
  final List<StockData> stockList;
  final bool isShop;
  final VoidCallback onAddStock;

  const DesktopInventorySidebar({
    super.key,
    required this.stockList,
    required this.isShop,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final attention =
        stockList
            .where((e) => e.isLowStock == true || e.isOutOfStock == true)
            .toList()
          ..sort((a, b) {
            final aOut = a.isOutOfStock == true ? 0 : 1;
            final bOut = b.isOutOfStock == true ? 0 : 1;
            return aOut.compareTo(bOut);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickActionsCard(onAddStock: onAddStock),
        const SizedBox(height: AppDims.s4),
        _SidebarPanel(
          icon: SolarIconsOutline.dangerTriangle,
          iconColor: context.appColors.stockLow,
          title: 'Needs Attention',
          count: attention.length,
          emptyIcon: SolarIconsOutline.checkCircle,
          emptyMessage: 'All stock levels look healthy',
          items: attention.take(6).toList(),
          itemBuilder: (item) => _AttentionRow(item: item),
        ),
        if (isShop) ...[
          const SizedBox(height: AppDims.s4),
          const _ExpiryAlertsPanel(),
        ],
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onAddStock;

  const _QuickActionsCard({required this.onAddStock});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          FilledButton.icon(
            onPressed: onAddStock,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            icon: const Icon(
              SolarIconsOutline.addCircle,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              'Add Stock',
              style: AppTextStyles.bs200(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final IconData emptyIcon;
  final String emptyMessage;
  final List<StockData> items;
  final Widget Function(StockData item) itemBuilder;

  const _SidebarPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(icon: icon, iconColor: iconColor, title: title, count: count),
          if (items.isEmpty) ...[
            const SizedBox(height: AppDims.s4),
            Column(
              children: [
                Icon(
                  emptyIcon,
                  size: 26,
                  color: colors.textHint.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppDims.s2),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sm300(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s2),
          ] else ...[
            const SizedBox(height: AppDims.s3),
            for (var i = 0; i < items.length; i++) ...[
              if (i != 0) const SizedBox(height: AppDims.s2),
              itemBuilder(items[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;

  const _PanelHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.sm100(context).copyWith(
                color: iconColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Needs attention rows ─────────────────────────────────────────────────────

class _AttentionRow extends StatelessWidget {
  final StockData item;

  const _AttentionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOut = item.isOutOfStock == true;
    final color = isOut ? colors.danger : colors.stockLow;

    return _SidebarRow(
      onTap: () {
        final allStock = context.read<InventoryBloc>().state.stockList;
        showStockActionSheet(context, stock: item, allStock: allStock);
      },
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: item.productName ?? 'Product',
      subtitle: item.shopName ?? 'Shop',
      trailing: Text(
        _formatQty(item.qty),
        style: AppTextStyles.bs200(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _SidebarRow extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SidebarRow({
    this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  State<_SidebarRow> createState() => _SidebarRowState();
}

class _SidebarRowState extends State<_SidebarRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: _hovered ? colors.surfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          widget.leading,
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s2),
          widget.trailing,
        ],
      ),
    );

    if (widget.onTap == null) return row;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          child: row,
        ),
      ),
    );
  }
}

// ── Expiry alerts panel ──────────────────────────────────────────────────────

/// Inline version of [ExpiryAlertsScreen]: lists expired and soon-to-expire
/// batches directly in the sidebar so shops can spot them without navigating
/// away from the inventory grid.
class _ExpiryAlertsPanel extends StatefulWidget {
  const _ExpiryAlertsPanel();

  @override
  State<_ExpiryAlertsPanel> createState() => _ExpiryAlertsPanelState();
}

class _ExpiryAlertsPanelState extends State<_ExpiryAlertsPanel> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<ExpiryBloc>();
    if (bloc.state.status == ExpiryStatus.initial) {
      bloc.add(const OnExpiryAlertsInitial());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: BlocBuilder<ExpiryBloc, ExpiryState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeader(
                icon: SolarIconsOutline.calendar,
                iconColor: colors.warning,
                title: 'Expiring Soon',
                count: state.status == ExpiryStatus.success
                    ? state.alerts.length
                    : 0,
              ),
              ..._buildBody(context, state),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, ExpiryState state) {
    final colors = context.appColors;

    switch (state.status) {
      case ExpiryStatus.initial:
      case ExpiryStatus.loading:
        return [
          const SizedBox(height: AppDims.s3),
          for (var i = 0; i < 3; i++) ...[
            if (i != 0) const SizedBox(height: AppDims.s3),
            const _ExpiryRowSkeleton(),
          ],
        ];

      case ExpiryStatus.failure:
        return [
          const SizedBox(height: AppDims.s4),
          Icon(
            SolarIconsOutline.cloudCross,
            size: 26,
            color: colors.textHint.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            state.error ?? 'Failed to load expiry alerts',
            textAlign: TextAlign.center,
            style: AppTextStyles.sm300(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Center(
            child: TextButton(
              onPressed: () => context.read<ExpiryBloc>().add(
                const OnExpiryAlertsInitial(),
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.sm300(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ];

      case ExpiryStatus.success:
        if (state.alerts.isEmpty) {
          return [
            const SizedBox(height: AppDims.s4),
            Icon(
              SolarIconsOutline.shieldCheck,
              size: 26,
              color: colors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              'Nothing expiring soon',
              textAlign: TextAlign.center,
              style: AppTextStyles.sm300(context).copyWith(
                color: colors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDims.s2),
          ];
        }

        final expired = state.expired;
        final expiringSoon = state.expiringSoon;

        return [
          const SizedBox(height: AppDims.s3),
          if (expired.isNotEmpty) ...[
            _ExpiryGroupLabel(
              label: 'Expired',
              count: expired.length,
              color: colors.danger,
            ),
            const SizedBox(height: AppDims.s2),
            for (var i = 0; i < expired.length; i++) ...[
              if (i != 0) const SizedBox(height: AppDims.s2),
              _ExpiryRow(item: expired[i]),
            ],
          ],
          if (expired.isNotEmpty && expiringSoon.isNotEmpty)
            const SizedBox(height: AppDims.s3),
          if (expiringSoon.isNotEmpty) ...[
            if (expired.isNotEmpty) ...[
              _ExpiryGroupLabel(
                label: 'Expiring Soon',
                count: expiringSoon.length,
                color: colors.warning,
              ),
              const SizedBox(height: AppDims.s2),
            ],
            for (var i = 0; i < expiringSoon.length; i++) ...[
              if (i != 0) const SizedBox(height: AppDims.s2),
              _ExpiryRow(item: expiringSoon[i]),
            ],
          ],
        ];
    }
  }
}

class _ExpiryGroupLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ExpiryGroupLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDims.s2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.sm100(context).copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  final ExpiryAlertData item;

  const _ExpiryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isExpired = item.isExpiredSafe;
    final color = isExpired ? colors.danger : colors.warning;
    final days = item.calculatedExpiresInDays;

    final label = isExpired
        ? days == null
              ? 'Expired'
              : 'Expired ${-days}d ago'
        : days == null
        ? 'Soon'
        : days <= 0
        ? 'Today'
        : '${days}d';

    return _SidebarRow(
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: item.productName ?? 'Product',
      subtitle: item.shopName ?? 'Shop',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.sm100(context).copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ExpiryRowSkeleton extends StatelessWidget {
  const _ExpiryRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDims.s1),
      child: Row(
        children: [
          Shimmer(width: 8, height: 8, radius: 4),
          SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Shimmer(width: 120, height: 11, radius: 4),
                SizedBox(height: 6),
                Shimmer(width: 70, height: 9, radius: 4),
              ],
            ),
          ),
          SizedBox(width: AppDims.s2),
          Shimmer(width: 32, height: 16, radius: 999),
        ],
      ),
    );
  }
}
