import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SettingsGroupCard extends StatelessWidget {
  final List<Widget> items;

  const SettingsGroupCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            RepaintBoundary(child: items[index]),
            if (index < items.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: AppDims.s4 + 44 + AppDims.s3,
                color: colors.border.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}