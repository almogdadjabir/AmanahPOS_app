import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_tile.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailsSheet({super.key,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDims.s3),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.color,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: AppDims.s3),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs100(context).copyWith(
                            color: config.color,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatFullDate(item.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDims.s2),

                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          SolarIconsOutline.closeCircle,
                          size: 24,
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
              thickness: 1,
              color: colors.border.withValues(alpha: 0.70),
            ),

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
                      style: AppTextStyles.bs700(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: AppDims.s4),

                    Text(
                      body,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.55,
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
