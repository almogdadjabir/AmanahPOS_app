import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';

class WorkspaceQuickLinkPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final int animDelay;
  final VoidCallback onTap;

  const WorkspaceQuickLinkPill({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    this.animDelay = 0,
    required this.onTap,
  });

  @override
  State<WorkspaceQuickLinkPill> createState() =>
      _WorkspaceQuickLinkPillState();
}

class _WorkspaceQuickLinkPillState extends State<WorkspaceQuickLinkPill> {
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
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(
              AppDims.s2,
              AppDims.s2,
              AppDims.s4,
              AppDims.s2,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? accent.withValues(alpha: isDark ? 0.10 : 0.06)
                  : colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _hovered
                    ? accent.withValues(alpha: 0.55)
                    : colors.border.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(widget.icon, color: accent, size: 14),
                ),
                const SizedBox(width: AppDims.s2),
                Text(
                  widget.label,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .mAnimate()
        .fadeIn(
          duration: 320.ms,
          delay: Duration(milliseconds: widget.animDelay),
        )
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }
}
