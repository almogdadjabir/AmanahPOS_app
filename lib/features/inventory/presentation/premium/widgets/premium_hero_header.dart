import 'dart:math' as math;
import 'package:amana_pos/features/inventory/data/models/responses/premium_summary_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class PremiumHeroHeader extends StatelessWidget {
  final PremiumSummaryData? summary;
  final VoidCallback? onReceive;
  final bool isLoading;

  const PremiumHeroHeader({
    super.key,
    this.summary,
    this.onReceive,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [premiumHeroStart, premiumHeroPeak, premiumHeroEnd],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Aurora overlays
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goldDeep.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDims.s4, AppDims.s3, AppDims.s4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(),
                  const SizedBox(height: AppDims.s1),
                  _SubtitleRow(summary: summary),
                  const SizedBox(height: AppDims.s3),
                  _ActionRow(onReceive: onReceive),
                  const SizedBox(height: AppDims.s3),
                  _KpiScroll(summary: summary, isLoading: isLoading),
                  const SizedBox(height: AppDims.s4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Inventory',
          style: AppTextStyles.bs400(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: AppDims.s2),
        const _PremiumBadge(),
        const Spacer(),
        const _StatusDot(),
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [gold, goldDeep, premiumAmber700],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SolarIconsOutline.handStars, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: AppTextStyles.sm100(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot();

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.5 + 0.5 * _controller.value),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Live',
            style: AppTextStyles.sm100(context).copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  final PremiumSummaryData? summary;
  const _SubtitleRow({this.summary});

  @override
  Widget build(BuildContext context) {
    final skus = summary?.stockItemsCount ?? 0;
    final vendors = summary?.activeVendorsCount ?? 0;
    return Text(
      '$skus SKUs · $vendors vendors',
      style: AppTextStyles.bs300(context).copyWith(
        color: Colors.white.withValues(alpha: 0.65),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback? onReceive;
  const _ActionRow({this.onReceive});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Receive Stock CTA
        GestureDetector(
          onTap: onReceive,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [goldDeep, premiumAmber700],
              ),
              borderRadius: BorderRadius.circular(AppDims.rMd),
              boxShadow: [
                BoxShadow(
                  color: goldDeep.withValues(alpha: 0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(SolarIconsOutline.box, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Receive Stock',
                  style: AppTextStyles.bs300(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDims.s2),
        _GhostButton(
          icon: SolarIconsOutline.export,
          label: 'Export',
        ),
        const SizedBox(width: AppDims.s2),
        _GhostButton(
          icon: SolarIconsOutline.qrCode,
          label: 'Scan',
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GhostButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.bs200(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _KpiScroll extends StatelessWidget {
  final PremiumSummaryData? summary;
  final bool isLoading;

  const _KpiScroll({this.summary, required this.isLoading});

  double _healthPct(PremiumSummaryData? s) {
    if (s == null || s.stockItemsCount == 0) return 0;
    final unhealthy = s.lowStockCount + s.outOfStockCount;
    return math.max(
        0,
        math.min(
            100,
            (s.stockItemsCount - unhealthy) /
                s.stockItemsCount *
                100));
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final health = _healthPct(s);
    final inStock = s == null
        ? 0
        : s.stockItemsCount - s.lowStockCount - s.outOfStockCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _KpiCard(
            title: 'Inventory Health',
            value: '${health.toInt()}%',
            sub: '$inStock / ${s?.stockItemsCount ?? 0} healthy',
            accent: const Color(0xFF5EEAD4),
            isLoading: isLoading,
          ),
          const SizedBox(width: AppDims.s2),
          _KpiCard(
            title: 'Needs Restock',
            value:
                '${(s?.lowStockCount ?? 0) + (s?.outOfStockCount ?? 0)}',
            sub:
                '${s?.lowStockCount ?? 0} low · ${s?.outOfStockCount ?? 0} out',
            accent: const Color(0xFFFCD34D),
            isLoading: isLoading,
          ),
          const SizedBox(width: AppDims.s2),
          _KpiCard(
            title: 'Inbound This Month',
            value: '${s?.inboundThisMonthCount ?? 0}',
            sub: '${s?.receivedQuantityThisMonth ?? '0'} units received',
            accent: const Color(0xFF93C5FD),
            isLoading: isLoading,
          ),
          const SizedBox(width: AppDims.s2),
          _KpiCard(
            title: 'Expiring ≤30 days',
            value: '${s?.expiringSoonCount ?? 0}',
            sub: '${s?.expiredCount ?? 0} already expired',
            accent: const Color(0xFFFCA5A5),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color accent;
  final bool isLoading;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.accent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bs200(context).copyWith(
              color: Colors.white.withValues(alpha: 0.60),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? Container(
                  width: 60,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  value,
            style: AppTextStyles.bs800(context).copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs300(context).copyWith(
            color: Colors.white.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
