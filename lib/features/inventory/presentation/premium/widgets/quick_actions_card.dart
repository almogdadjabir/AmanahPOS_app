import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onReceive;
  final VoidCallback? onAdjust;
  final VoidCallback? onVendors;
  final VoidCallback? onReport;

  const QuickActionsCard({
    super.key,
    this.onReceive,
    this.onAdjust,
    this.onVendors,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            title: 'Quick Actions',
            icon: SolarIconsOutline.widget,
            accent: gold,
          ),
          const SizedBox(height: AppDims.s3),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: SolarIconsOutline.box,
                  label: 'Receive',
                  color: goldDeep,
                  onTap: onReceive,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ActionButton(
                  icon: SolarIconsOutline.settings,
                  label: 'Adjust',
                  color: const Color(0xFF93C5FD),
                  onTap: onAdjust,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ActionButton(
                  icon: SolarIconsOutline.shop,
                  label: 'Vendors',
                  color: const Color(0xFF5EEAD4),
                  onTap: onVendors,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ActionButton(
                  icon: SolarIconsOutline.notes,
                  label: 'Report',
                  color: const Color(0xFFFCA5A5),
                  onTap: onReport,
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
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
