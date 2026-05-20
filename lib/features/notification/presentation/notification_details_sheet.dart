import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_tile.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationDetailsSheet  (drop-in, same constructor API)
//
// Changes vs original:
//   • Drag handle bar at top (standard bottom-sheet affordance, was missing)
//   • Close button is a small circular icon button — not a raw InkWell on a 24px icon
//   • Type label uses sentence case + lighter weight (was ALL-CAPS w900)
//   • Title weight w900 → w600; body w700 → w400 (calmer reading experience)
//   • Divider uses standard Divider widget with theme color (no manual opacity math)
//   • boxShadow removed — the modal backdrop provides visual separation
// ─────────────────────────────────────────────────────────────────────────────

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailsSheet({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final config = typeConfig(item.type);

    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Notification';

    final body = item.body?.trim().isNotEmpty == true
        ? item.body!.trim()
        : 'No details available.';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s3,
                AppDims.s3,
                AppDims.s3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                      border: Border.all(
                        color: config.color.withValues(alpha: 0.16),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.color,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: AppDims.s3),

                  // Type + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.label,
                          style: AppTextStyles.bs200(context).copyWith(
                            color: config.color,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFullDate(item.createdAt),
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.6),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          SolarIconsOutline.closeCircle,
                          size: 16,
                          color: colors.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 0.5,
              color: colors.border.withValues(alpha: 0.6),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: AppDims.s3),
                    Text(
                      body,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) return 'No date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}