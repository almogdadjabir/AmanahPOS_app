import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:flutter/material.dart';

/// Small "Not synced" / "Sync failed" pill of a catalog row (product,
/// category, vendor), same look as the sales history pills. Nothing for a
/// synced row.
class CatalogSyncPill extends StatelessWidget {
  final CatalogSyncMark mark;

  const CatalogSyncPill({super.key, required this.mark});

  @override
  Widget build(BuildContext context) {
    if (mark == CatalogSyncMark.synced) return const SizedBox.shrink();
    final colors = context.appColors;
    final tr = context.tr;
    final failed = mark == CatalogSyncMark.failed;
    final (bg, fg) = failed
        ? (colors.dangerContainer, colors.danger)
        : (colors.surfaceSoft, colors.textSecondary);
    return Container(
      key: ValueKey('catalog-sync-${mark.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failed ? PhosphorIconsRegular.warning : PhosphorIconsRegular.clock,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            failed ? tr.shPillSyncFailed : tr.shPillNotSynced,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
