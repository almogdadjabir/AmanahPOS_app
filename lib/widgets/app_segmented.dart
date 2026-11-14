import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Widget? leading;

  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.leading,
  });
}

/// Segmented control with a sliding thumb (Apple sheet curve, 260ms).
class AppSegmented<T> extends StatelessWidget {
  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Optional live thumb position in segment units (0..n-1), e.g. driven by a
  /// PageView so the thumb follows the finger. Falls back to [selected].
  final ValueListenable<double>? progress;

  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.progress,
  });

  static const double _height = 32;
  static const double _inset = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final index = segments.indexWhere((s) => s.value == selected);
    final duration = Motion.duration(AppDims.sheet);

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;

          return Stack(
            children: [
              if (progress != null)
                ValueListenableBuilder<double>(
                  valueListenable: progress!,
                  builder: (context, value, _) => PositionedDirectional(
                    start: value * segmentWidth,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: _Thumb(colors: colors),
                  ),
                )
              else
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: AppDims.sheetCurve,
                  start: (index < 0 ? 0 : index) * segmentWidth,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: _Thumb(colors: colors),
                ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: _SegmentLabel(
                        segment: segment,
                        isSelected: segment.value == selected,
                        onTap: () {
                          if (segment.value == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(segment.value);
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final AppThemeColors colors;
  const _Thumb({required this.colors});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  final AppSegment<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentLabel({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isSelected ? colors.textPrimary : colors.textSecondary;

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      semanticLabel: segment.label,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segment.leading != null) ...[
              segment.leading!,
              const SizedBox(width: AppDims.s2),
            ] else if (segment.icon != null) ...[
              Icon(segment.icon, size: 16, color: color),
              const SizedBox(width: AppDims.s1 + 2),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: Motion.duration(AppDims.medium),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontSize: 13,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
