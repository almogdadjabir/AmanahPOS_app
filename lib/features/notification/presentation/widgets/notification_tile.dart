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
// Changes vs original:
//   • Left accent bar (3px) replaces box-shadow — visible in all light conditions
//   • Unread tint is applied only to background, not border, reducing visual noise
//   • Typography toned down: w700→w500 title, w700→w400 body (less shouting)
//   • Type badge moved inline with time, arrow icon removed (redundant on a tap target)
//   • Unread dot stays — repositioned to top-right of icon box, not inline with text
//   • Icon box slightly smaller (40→36px) for better proportion on dense lists
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
    final config = typeConfig(item.type);

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
          decoration: BoxDecoration(
            color: isUnread
                ? config.color.withValues(alpha: 0.04)
                : colors.surface,
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
                // ── Left accent bar ─────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? config.color
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDims.rLg),
                      bottomLeft: Radius.circular(AppDims.rLg),
                    ),
                  ),
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
                                            : FontWeight.w500,
                                        color: colors.textPrimary,
                                        height: 1.2,
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
                                const SizedBox(height: 5),
                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bs200(context).copyWith(
                                    color: colors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],

                              // Footer: type badge only
                              const SizedBox(height: 8),
                              _TypeBadge(config: config),
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
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isRead ? 0.07 : 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isRead ? 0.10 : 0.18),
          width: 0.5,
        ),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypeBadge
// ─────────────────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final TypeConfig config;
  const _TypeBadge({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: config.color.withValues(alpha: 0.14),
          width: 0.5,
        ),
      ),
      child: Text(
        config.label,
        style: AppTextStyles.bs100(context).copyWith(
          color: config.color,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showNotificationDetailsSheet  (unchanged — kept here for co-location)
// ─────────────────────────────────────────────────────────────────────────────

void showNotificationDetailsSheet(
    BuildContext context, {
      required NotificationItem item,
    }) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NotificationDetailsSheet(item: item),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TypeConfig + typeConfig  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class TypeConfig {
  final IconData icon;
  final Color color;
  final String label;

  const TypeConfig(this.icon, this.color, this.label);
}

TypeConfig typeConfig(String type) {
  switch (type) {
    case 'success':
      return const TypeConfig(
          SolarIconsOutline.checkCircle, Color(0xFF16A34A), 'Success');
    case 'warning':
      return const TypeConfig(
          SolarIconsOutline.dangerTriangle, Color(0xFFF59E0B), 'Warning');
    case 'error':
      return const TypeConfig(
          SolarIconsOutline.dangerCircle, Color(0xFFEF4444), 'Error');
    case 'sale':
      return const TypeConfig(
          SolarIconsOutline.billList, Color(0xFF0D9488), 'Sale');
    case 'stock':
      return const TypeConfig(
          SolarIconsOutline.box, Color(0xFFEC4899), 'Stock');
    case 'subscription':
      return const TypeConfig(
          SolarIconsOutline.card, Color(0xFF8B5CF6), 'Plan');
    case 'security':
      return const TypeConfig(
          SolarIconsOutline.shieldCheck, Color(0xFFF59E0B), 'Security');
    case 'system':
      return const TypeConfig(
          SolarIconsOutline.settings, Color(0xFF6B7280), 'System');
    case 'info':
    default:
      return const TypeConfig(
          SolarIconsOutline.infoCircle, Color(0xFF0EA5E9), 'Info');
  }
}