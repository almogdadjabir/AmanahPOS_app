import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

enum AppTint { brand, cash, digital, success, warning, danger, info, neutral }

/// Inset grouped list like iOS Settings: rounded surface, hairline
/// separators inset past the icon.
class AppGroup extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const AppGroup({super.key, required this.children, this.header, this.footer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s4,
              0,
              AppDims.s4,
              AppDims.s2,
            ),
            child: Text(
              header!,
              style: text.labelLarge!.copyWith(color: colors.textSecondary),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: AppDims.borderLg,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const _GroupDivider(),
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s4,
              AppDims.s2,
              AppDims.s4,
              0,
            ),
            child: Text(
              footer!,
              style: text.bodySmall!.copyWith(color: colors.textHint),
            ),
          ),
      ],
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppDims.s4 + AppGroupRow.iconTileSize + AppDims.s3,
      endIndent: 0,
      color: context.appColors.border,
    );
  }
}

class AppGroupRow extends StatelessWidget {
  static const double iconTileSize = 30;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final AppTint tint;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;
  final VoidCallback? onTap;

  const AppGroupRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tint = AppTint.brand,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            AppIconTile(icon: icon!, tint: tint),
            const SizedBox(width: AppDims.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.bodyLarge!.copyWith(
                    color: destructive ? colors.danger : colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: text.bodySmall!.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppDims.s2),
            Text(
              value!,
              style: text.bodyMedium!.copyWith(color: colors.textHint),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppDims.s2),
            trailing!,
          ],
          if (showChevron && onTap != null) ...[
            const SizedBox(width: AppDims.s1),
            DirectionalIcon(
              icon: PhosphorIconsRegular.caretRight,
              size: 20,
              color: colors.borderStrong,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Pressable(onTap: onTap, scale: 1, child: row);
  }
}

/// 30px tinted icon tile used in grouped rows and menus.
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final AppTint tint;
  final double size;

  const AppIconTile({
    super.key,
    required this.icon,
    this.tint = AppTint.brand,
    this.size = AppGroupRow.iconTileSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final (bg, fg) = switch (tint) {
      AppTint.brand => (colors.primaryContainer, colors.primary),
      AppTint.cash => (colors.cashTint, colors.cashInk),
      AppTint.digital => (colors.digitalTint, colors.digitalInk),
      AppTint.success => (colors.successContainer, colors.success),
      AppTint.warning => (colors.warningContainer, colors.warning),
      AppTint.danger => (colors.dangerContainer, colors.danger),
      AppTint.info => (colors.infoContainer, colors.info),
      AppTint.neutral => (colors.surfaceSoft, colors.textSecondary),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDims.rSm - 1),
      ),
      child: Icon(icon, size: size * 0.55, color: fg),
    );
  }
}
