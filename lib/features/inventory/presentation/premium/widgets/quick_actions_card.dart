import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onReceive;
  final VoidCallback? onStockLevels;
  final VoidCallback? onVendors;
  final VoidCallback? onExpiry;

  const QuickActionsCard({
    super.key,
    this.onReceive,
    this.onStockLevels,
    this.onVendors,
    this.onExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: tr.invQuickActionsTitle,
            icon: PhosphorIconsRegular.squaresFour,
            accent: gold,
          ),
          const SizedBox(height: AppDims.s3),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: PhosphorIconsRegular.package,
                  label: tr.invReceive,
                  color: goldDeep,
                  onTap: onReceive,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ActionButton(
                  icon: PhosphorIconsRegular.stack,
                  label: tr.invStockAction,
                  color: const Color(0xFF93C5FD),
                  onTap: onStockLevels,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ActionButton(
                  icon: PhosphorIconsRegular.storefront,
                  label: tr.invVendors,
                  color: const Color(0xFF5EEAD4),
                  onTap: onVendors,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ActionButton(
                  icon: PhosphorIconsRegular.calendarCheck,
                  label: tr.invExpiry,
                  color: const Color(0xFFFCA5A5),
                  onTap: onExpiry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}