import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleEmptyState extends StatelessWidget {
  const SaleEmptyState({
    super.key,
    required this.filter,
    required this.hasSearch,
  });

  final SaleFilter filter;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final data = _emptyStateData(context);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s5),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyIcon(
                icon: data.icon,
                color: colors.primary,
              ),
              const SizedBox(height: AppDims.s3),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SaleEmptyStateData _emptyStateData(BuildContext context) {
    final tr = context.tr;

    if (hasSearch) {
      return _SaleEmptyStateData(
        icon: SolarIconsOutline.magnifierZoomOut,
        title: tr.noMatchingSales,
        subtitle: tr.tryDifferentSearchTerm,
      );
    }

    return switch (filter) {
      SaleFilter.today => _SaleEmptyStateData(
        icon: SolarIconsOutline.calendarDate,
        title: tr.noSalesToday,
        subtitle: tr.salesMadeTodayWillAppearHere,
      ),
      SaleFilter.pending => _SaleEmptyStateData(
        icon: SolarIconsOutline.clockCircle,
        title: tr.noPendingSales,
        subtitle: tr.allOfflineSalesSynced,
      ),
      SaleFilter.completed => _SaleEmptyStateData(
        icon: SolarIconsOutline.checkCircle,
        title: tr.noCompletedSales,
        subtitle: tr.matchingSalesWillAppearHere,
      ),
      SaleFilter.refunded => _SaleEmptyStateData(
        icon: SolarIconsOutline.undoLeft,
        title: tr.noReturnedSales,
        subtitle: tr.matchingSalesWillAppearHere,
      ),
      SaleFilter.all => _SaleEmptyStateData(
        icon: SolarIconsOutline.list,
        title: tr.noSalesYet,
        subtitle: tr.salesWillAppearHere,
      ),
    };
  }
}

class _EmptyIcon extends StatelessWidget {
  const _EmptyIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: SizedBox(
        width: 74,
        height: 74,
        child: Icon(
          icon,
          size: 36,
          color: color,
        ),
      ),
    );
  }
}

class _SaleEmptyStateData {
  const _SaleEmptyStateData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}