import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/presentation/notification_details_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationTile  (drop-in, same constructor API)
//
// Refined treatment:
//   • One accent colour per row (icon + accent bar + unread dot) — the type
//     badge is removed (the icon already encodes the type).
//   • Type colours come from the theme (success / warning / danger / info /
//     primary / sale), so they adapt to dark mode instead of hardcoded hex.
//   • Read rows go quiet: no accent bar, muted title/body. Unread rows keep the
//     accent bar, a filled dot, and a slightly stronger title.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final config = typeConfig(colors, item.type);

    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Notification';

    final body = item.body?.trim();
    final isUnread = !item.isRead;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: isUnread
                  ? config.color.withValues(alpha: 0.16)
                  : colors.border.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent bar (unread only) ───────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  color: isUnread ? config.color : Colors.transparent,
                ),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon + unread dot
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _IconBox(
                              icon: config.icon,
                              color: config.color,
                              isRead: item.isRead,
                            ),
                            if (isUnread)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: config.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: AppDims.s3),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + time
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                      AppTextStyles.bs400(context).copyWith(
                                        fontWeight: isUnread
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isUnread
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(item.createdAt),
                                    style:
                                    AppTextStyles.bs100(context).copyWith(
                                      color: colors.textHint,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              // Body
                              if (body != null && body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bs200(context).copyWith(
                                    color: isUnread
                                        ? colors.textSecondary
                                        : colors.textHint,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _IconBox
// ─────────────────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isRead;

  const _IconBox({
    required this.icon,
    required this.color,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isRead ? 0.07 : 0.12),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showNotificationDetailsSheet  (co-located helper, unchanged)
// ─────────────────────────────────────────────────────────────────────────────

void showNotificationDetailsSheet(
    BuildContext context, {
      required NotificationItem item,
    }) {
  showAdaptivePanel<void>(
    context,
    desktopWidth: 360,
    builder: (_) => NotificationDetailsSheet(item: item),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TypeConfig + typeConfig  (theme-driven)
// ─────────────────────────────────────────────────────────────────────────────

class TypeConfig {
  final IconData icon;
  final Color color;
  final String label;

  const TypeConfig(this.icon, this.color, this.label);
}

/// Maps a notification [type] to an icon, a theme colour, and a label.
/// Colours are pulled from [AppThemeColors] so they adapt to light/dark mode.
TypeConfig typeConfig(AppThemeColors colors, String type) {
  switch (type) {
    case 'success':
      return TypeConfig(SolarIconsOutline.checkCircle, colors.success, 'Success');
    case 'warning':
      return TypeConfig(SolarIconsOutline.dangerTriangle, colors.warning, 'Warning');
    case 'error':
      return TypeConfig(SolarIconsOutline.dangerCircle, colors.danger, 'Error');
    case 'sale':
      return TypeConfig(SolarIconsOutline.billList, colors.sale, 'Sale');
    case 'stock':
      return TypeConfig(SolarIconsOutline.box, colors.warning, 'Stock');
    case 'subscription':
      return TypeConfig(SolarIconsOutline.card, colors.primary, 'Plan');
    case 'security':
      return TypeConfig(SolarIconsOutline.shieldCheck, colors.warning, 'Security');
    case 'system':
      return TypeConfig(SolarIconsOutline.settings, colors.textSecondary, 'System');
    case 'info':
    default:
      return TypeConfig(SolarIconsOutline.infoCircle, colors.info, 'Info');
  }
}