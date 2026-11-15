import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// Icon and tint for a notification type: success, warning, error or info.
class NotificationTone {
  final IconData icon;
  final Color fill;
  final Color ink;

  const NotificationTone(this.icon, this.fill, this.ink);
}

NotificationTone notificationTone(AppThemeColors colors, String type) {
  switch (type) {
    case 'success':
    case 'sale':
      return NotificationTone(
        PhosphorIconsRegular.checkCircle,
        colors.successContainer,
        colors.success,
      );
    case 'warning':
    case 'stock':
    case 'security':
      return NotificationTone(
        PhosphorIconsRegular.warning,
        colors.warningContainer,
        colors.warning,
      );
    case 'error':
      return NotificationTone(
        PhosphorIconsRegular.warning,
        colors.dangerContainer,
        colors.danger,
      );
    default:
      return NotificationTone(
        PhosphorIconsRegular.bell,
        colors.primaryContainer,
        colors.primary,
      );
  }
}

/// 40 tinted tile used in the list and in the detail sheet.
class NotificationTile extends StatelessWidget {
  final String type;
  final double size;

  const NotificationTile({super.key, required this.type, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final tone = notificationTone(context.appColors, type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.circular(size >= 48 ? 14 : 11),
      ),
      child: Icon(tone.icon, size: 21, color: tone.ink),
    );
  }
}

/// One row: tinted tile, title, two lines of body, when. Unread rows are
/// semibold with a brand dot at the end.
class NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : context.tr.nfDetailTitle;
    final body = item.body?.trim() ?? '';
    final unread = !item.isRead;

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s4,
            12,
            AppDims.s4,
            13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationTile(type: item.type),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge!.copyWith(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (body.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!.copyWith(
                            fontSize: 14,
                            height: 19 / 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    if (item.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          saleWhen(context, item.createdAt!),
                          style: text.bodySmall!.copyWith(
                            fontSize: 12,
                            color: colors.textHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 9 + AppDims.s2,
                child: unread
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: 7,
                          start: AppDims.s2,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(width: 9, height: 9),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
