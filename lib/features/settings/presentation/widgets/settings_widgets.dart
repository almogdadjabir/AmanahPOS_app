import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fixed-fill tile colours of the More screen (30px tile, glyph in surface).
enum SettingsTile { teal, indigo, slate, red, green, amber, blue }

(Color, Color) _tileColors(AppThemeColors c, SettingsTile t) {
  final fill = switch (t) {
    SettingsTile.teal => c.primary,
    SettingsTile.indigo => c.digitalInk,
    SettingsTile.slate => c.textSecondary,
    SettingsTile.red => c.danger,
    SettingsTile.green => c.success,
    SettingsTile.amber => c.cashInk,
    SettingsTile.blue => c.info,
  };
  final glyph = t == SettingsTile.teal ? c.onPrimary : c.surface;
  return (fill, glyph);
}

/// Section label (13, hint), rounded card with hairlines inset past the tile,
/// and an optional footer, like iOS Settings.
class SettingsGroup extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final double dividerInset;

  const SettingsGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.dividerInset = 60,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
            child: Text(
              header!,
              style: TextStyle(fontSize: 13, color: colors.textHint),
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
                  if (i < children.length - 1)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: dividerInset,
                      endIndent: 0,
                      color: colors.border,
                    ),
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: colors.textHint,
              ),
            ),
          ),
      ],
    );
  }
}

/// One More row: 30px tile, 17px title, value and chevron at the end.
class SettingsRow extends StatelessWidget {
  final SettingsTile tile;
  final IconData icon;
  final String title;
  final String? value;
  final Color? valueColor;
  final bool dot;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.tile,
    required this.icon,
    required this.title,
    this.value,
    this.valueColor,
    this.dot = false,
    this.trailing,
    this.chevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (fill, glyph) = _tileColors(colors, tile);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: glyph),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, color: colors.textPrimary),
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null) ...[
                const SizedBox(width: AppDims.s3),
                if (dot) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: valueColor ?? colors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.5,
                  ),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      color: dot
                          ? colors.textSecondary
                          : valueColor ?? colors.textSecondary,
                      fontWeight: !dot && valueColor != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
              if (chevron && onTap != null) ...[
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Pressable(onTap: onTap, scale: 1, child: row);
  }
}

/// Switch for a [SettingsRow] trailing slot.
class SettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      activeTrackColor: context.appColors.primary,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }
}

/// 44px nav bar: back arrow with a label, optional trailing text action.
class SettingsNavBar extends StatelessWidget {
  final String backLabel;
  final VoidCallback? onBack;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool saving;

  const SettingsNavBar({
    super.key,
    required this.backLabel,
    this.onBack,
    this.actionLabel,
    this.onAction,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      backLabel,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (actionLabel != null)
              Pressable(
                onTap: saving ? null : onAction,
                scale: 1,
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            )
                          : Text(
                              actionLabel!,
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: onAction == null
                                    ? colors.disabled
                                    : colors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
