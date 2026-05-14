import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

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
    final config = _typeConfig(item.type);

    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Notification';

    final body = item.body?.trim();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: item.isRead
                ? colors.surface
                : config.color.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: item.isRead
                  ? colors.border
                  : config.color.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIconBox(
                icon: config.icon,
                color: config.color,
                isRead: item.isRead,
              ),

              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs500(context).copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w800
                                  : FontWeight.w900,
                              color: colors.textPrimary,
                              height: 1.18,
                            ),
                          ),
                        ),

                        const SizedBox(width: AppDims.s2),

                        if (!item.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: config.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    if (body != null && body.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs300(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.38,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDims.s3),

                    Row(
                      children: [
                        _TypeBadge(config: config),
                        const SizedBox(width: AppDims.s2),
                        Expanded(
                          child: Text(
                            _formatDate(item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs100(context).copyWith(
                              color: colors.textHint,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          SolarIconsOutline.altArrowRight,
                          size: 16,
                          color: colors.textHint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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

void showNotificationDetailsSheet(
    BuildContext context, {
      required NotificationItem item,
    }) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationDetailsSheet(item: item),
  );
}

class _NotificationDetailsSheet extends StatelessWidget {
  final NotificationItem item;

  const _NotificationDetailsSheet({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final config = _typeConfig(item.type);

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
          children: [
            const SizedBox(height: AppDims.s3),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

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


class _NotificationIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isRead;

  const _NotificationIconBox({
    required this.icon,
    required this.color,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isRead ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: color.withValues(alpha: isRead ? 0.12 : 0.20),
        ),
      ),
      child: Icon(
        icon,
        size: 23,
        color: color,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final _TypeConfig config;

  const _TypeBadge({
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: config.color.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        config.label,
        style: AppTextStyles.bs100(context).copyWith(
          color: config.color,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _TypeConfig(
      this.icon,
      this.color,
      this.label,
      );
}

_TypeConfig _typeConfig(String type) {
  switch (type) {
    case 'success':
      return const _TypeConfig(
        SolarIconsOutline.checkCircle,
        Color(0xFF16A34A),
        'Success',
      );

    case 'warning':
      return const _TypeConfig(
        SolarIconsOutline.dangerTriangle,
        Color(0xFFF59E0B),
        'Warning',
      );

    case 'error':
      return const _TypeConfig(
        SolarIconsOutline.dangerCircle,
        Color(0xFFEF4444),
        'Error',
      );

    case 'sale':
      return const _TypeConfig(
        SolarIconsOutline.billList,
        Color(0xFF0D9488),
        'Sale',
      );

    case 'stock':
      return const _TypeConfig(
        SolarIconsOutline.box,
        Color(0xFFEC4899),
        'Stock',
      );

    case 'subscription':
      return const _TypeConfig(
        SolarIconsOutline.card,
        Color(0xFF8B5CF6),
        'Plan',
      );

    case 'security':
      return const _TypeConfig(
        SolarIconsOutline.shieldCheck,
        Color(0xFFF59E0B),
        'Security',
      );

    case 'system':
      return const _TypeConfig(
        SolarIconsOutline.settings,
        Color(0xFF6B7280),
        'System',
      );

    case 'info':
    default:
      return const _TypeConfig(
        SolarIconsOutline.infoCircle,
        Color(0xFF0EA5E9),
        'Info',
      );
  }
}