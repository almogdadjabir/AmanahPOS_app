import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_tile.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

Future<void> showNotificationDetailsSheet(
  BuildContext context, {
  required NotificationItem item,
}) {
  return showAppSheet<void>(
    context,
    builder: (ctx) => NotificationDetailsSheet(item: item),
  );
}

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : tr.nfDetailTitle;
    final body = item.body?.trim() ?? '';

    return AppSheet(
      title: tr.nfDetailTitle,
      maxHeightFactor: 0.7,
      trailingAction: AppSheetAction(
        label: tr.done,
        emphasized: true,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
            child: Row(
              children: [
                NotificationTile(type: item.type, size: 48),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium!.copyWith(
                          fontSize: 19,
                          height: 24 / 19,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (item.createdAt != null)
                        Text(
                          saleWhen(context, item.createdAt!),
                          style: text.bodySmall!.copyWith(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (body.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppDims.borderLg,
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s4,
                  vertical: 12,
                ),
                child: Text(
                  body,
                  style: text.bodyMedium!.copyWith(
                    fontSize: 16,
                    height: 23 / 16,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppDims.s4),
        ],
      ),
    );
  }
}
