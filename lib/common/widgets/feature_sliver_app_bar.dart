import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class FeatureSliverAppBar extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> additionalActions;

  const FeatureSliverAppBar({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(SolarIconsOutline.addCircle,
                size: 18, color: colors.primary),
            label: Text(
              actionLabel!,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ),
        ...additionalActions,
        const SizedBox(width: AppDims.s1),
      ],
    );
  }
}
