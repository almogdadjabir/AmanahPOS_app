import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Hover-aware tile used in the desktop "Manage" grid. Mirrors the desktop
/// module-card language from the business workspace, but laid out
/// horizontally to suit a settings list (icon, title + subtitle, chevron).
class DesktopManageTile extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DesktopManageTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<DesktopManageTile> createState() => _DesktopManageTileState();
}

class _DesktopManageTileState extends State<DesktopManageTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = widget.accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: _hovered
                  ? accent.withValues(alpha: isDark ? 0.10 : 0.06)
                  : colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(
                color: _hovered
                    ? accent.withValues(alpha: 0.55)
                    : colors.border.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                  ),
                  child: Icon(widget.icon, color: accent, size: 21),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sm300(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: SolarIconsOutline.altArrowRight,
                  size: 15,
                  color: _hovered ? accent : colors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
