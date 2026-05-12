import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

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

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: item.isRead
              ? colors.surface
              : colors.primaryContainer.withValues(alpha: 0.08),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDims.s4, AppDims.s4, AppDims.s3, AppDims.s4),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, size: 20, color: config.color),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDims.s3,
                  horizontal: AppDims.s2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title ?? 'Notification',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs500(context).copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDims.s2),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.label,
                            style: AppTextStyles.bs200(context).copyWith(
                              color: config.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (item.body != null && item.body!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs500(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 5),
                    Text(
                      _formatDate(item.createdAt),
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: AppDims.s3),
          ],
        ),
      ),
    );
  }


  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}


class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig(this.icon, this.color, this.label);
}

_TypeConfig _typeConfig(String type) {
  switch (type) {
    case 'success':
      return const _TypeConfig(
          Icons.check_circle_outline_rounded, Color(0xFF16A34A), 'Success');
    case 'warning':
      return const _TypeConfig(
          Icons.warning_amber_rounded, Color(0xFFF59E0B), 'Warning');
    case 'error':
      return const _TypeConfig(
          Icons.error_outline_rounded, Color(0xFFEF4444), 'Error');
    case 'sale':
      return const _TypeConfig(
          Icons.point_of_sale_rounded, Color(0xFF0D9488), 'Sale');
    case 'stock':
      return const _TypeConfig(
          Icons.inventory_2_rounded, Color(0xFFEC4899), 'Stock');
    case 'subscription':
      return const _TypeConfig(
          Icons.card_membership_rounded, Color(0xFF8B5CF6), 'Plan');
    case 'security':
      return const _TypeConfig(
          Icons.security_rounded, Color(0xFFF59E0B), 'Security');
    case 'system':
      return const _TypeConfig(
          Icons.settings_rounded, Color(0xFF6B7280), 'System');
    case 'info':
    default:
      return const _TypeConfig(
          Icons.info_outline_rounded, Color(0xFF0EA5E9), 'Info');
  }
}
