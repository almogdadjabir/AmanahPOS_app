import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_format.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/features/sync/presentation/widgets/sync_badge.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Large "Today" title, the date, and the data status at the end.
class HomeHeader extends StatelessWidget {
  final DashboardSummary? summary;
  final bool loading;

  const HomeHeader({super.key, required this.summary, required this.loading});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final s = summary;

    final (label, color) = loading || s == null
        ? (null, colors.textHint)
        : s.includesLocalPendingSales
        ? (tr.homeStatusOffline, colors.warning)
        : s.source == DashboardSummarySource.cache
        ? (tr.homeStatusCached, colors.textHint)
        : (tr.homeStatusLive, colors.success);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.today,
                  style: text.displayMedium!.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  homeDate(
                    s?.today.date ?? DateTime.now().toIso8601String(),
                    locale,
                  ),
                  style: text.bodyMedium!.copyWith(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (kSyncEngineEnabled)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: SyncBadge(),
            )
          else if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: text.labelMedium!.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
