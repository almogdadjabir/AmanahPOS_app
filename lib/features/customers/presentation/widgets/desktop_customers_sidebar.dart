import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_form_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Right-hand column of the desktop customers layout: quick actions, a
/// recent customers panel, and a loyalty leaders list at a glance.
class DesktopCustomersSidebar extends StatelessWidget {
  final List<CustomerData> customers;
  final VoidCallback onAddCustomer;

  const DesktopCustomersSidebar({
    super.key,
    required this.customers,
    required this.onAddCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final creditCustomers = customers
        .where((c) => _creditAmount(c) > 0)
        .toList()
      ..sort((a, b) => _creditAmount(b).compareTo(_creditAmount(a)));

    final loyaltyLeaders = customers.toList()
      ..sort(
        (a, b) => (b.loyaltyPoints ?? 0).compareTo(a.loyaltyPoints ?? 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickActionsCard(onAddCustomer: onAddCustomer),
        const SizedBox(height: AppDims.s4),
        _CustomerListPanel(
          icon: SolarIconsOutline.crown,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Loyalty Leaders',
          emptyIcon: SolarIconsOutline.star,
          emptyMessage: 'No loyalty points earned yet',
          items: loyaltyLeaders.take(6).toList(),
          itemBuilder: (customer) => _LoyaltyRow(customer: customer),
        ),
        if (creditCustomers.isNotEmpty) ...[
          const SizedBox(height: AppDims.s4),
          _CustomerListPanel(
            icon: SolarIconsOutline.walletMoney,
            iconColor: const Color(0xFFEA580C),
            title: 'Credit Accounts',
            emptyIcon: SolarIconsOutline.walletMoney,
            emptyMessage: 'No customers with credit balance',
            items: creditCustomers.take(6).toList(),
            itemBuilder: (customer) => _CreditRow(customer: customer),
          ),
        ],
      ],
    );
  }

  static double _creditAmount(CustomerData customer) {
    final raw = customer.totalPurchases?.trim();
    if (raw == null || raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onAddCustomer;

  const _QuickActionsCard({required this.onAddCustomer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

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
            onPressed: onAddCustomer,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            icon: const Icon(
              SolarIconsOutline.userPlus,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              tr.addCustomer,
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

class _CustomerListPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final IconData emptyIcon;
  final String emptyMessage;
  final List<CustomerData> items;
  final Widget Function(CustomerData) itemBuilder;

  const _CustomerListPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
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
          _PanelHeader(
            icon: icon,
            iconColor: iconColor,
            title: title,
            count: items.length,
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: AppDims.s4),
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

// ── Loyalty row ───────────────────────────────────────────────────────────────

class _LoyaltyRow extends StatelessWidget {
  final CustomerData customer;

  const _LoyaltyRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final points = customer.loyaltyPoints ?? 0;
    final color = const Color(0xFF8B5CF6);

    return _SidebarRow(
      onTap: () => showCustomerFormSheet(context, customer: customer),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          _initial(customer.name),
          style: AppTextStyles.sm100(context).copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: customer.name?.trim().isNotEmpty == true
          ? customer.name!.trim()
          : 'Customer',
      subtitle: customer.phone?.trim().isNotEmpty == true
          ? customer.phone!.trim()
          : customer.email?.trim() ?? '—',
      trailing: Text(
        '$points pts',
        style: AppTextStyles.bs200(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}

// ── Credit row ────────────────────────────────────────────────────────────────

class _CreditRow extends StatelessWidget {
  final CustomerData customer;

  const _CreditRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFEA580C);
    final amount = customer.totalPurchases?.trim() ?? '0';

    return _SidebarRow(
      onTap: () => showCustomerFormSheet(context, customer: customer),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          _LoyaltyRow._initial(customer.name),
          style: AppTextStyles.sm100(context).copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: customer.name?.trim().isNotEmpty == true
          ? customer.name!.trim()
          : 'Customer',
      subtitle: customer.phone?.trim().isNotEmpty == true
          ? customer.phone!.trim()
          : customer.email?.trim() ?? '—',
      trailing: Text(
        amount,
        style: AppTextStyles.bs200(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ── Reusable sidebar row ──────────────────────────────────────────────────────

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
