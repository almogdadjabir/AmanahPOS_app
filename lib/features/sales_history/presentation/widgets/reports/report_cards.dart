import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// White rounded card of the Reports column (HTML `.rc`).
class ReportCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ReportCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: colors.border) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            child,
          ],
        ),
      ),
    );
  }
}

/// Big number with a small hint beside it (HTML `.hl`).
class ReportHeadline extends StatelessWidget {
  final String value;
  final String? hint;

  const ReportHeadline({super.key, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.44,
                color: colors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (hint != null)
              TextSpan(
                text: '  $hint',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bars that always run left to right, tallest one in full brand colour and
/// the rest at 28% (HTML `.bars`).
class ReportBars extends StatelessWidget {
  final List<double> values;
  final double height;

  const ReportBars({super.key, required this.values, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    var max = 0.0;
    var peak = -1;
    for (var i = 0; i < values.length; i++) {
      if (values[i] > max) {
        max = values[i];
        peak = i;
      }
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: max <= 0
                      ? 0.02
                      : (values[i] / max).clamp(0.02, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: i == peak ? 1 : 0.28,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                        bottom: Radius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Axis labels under the bars, spread edge to edge, always left to right.
class ReportAxis extends StatelessWidget {
  final List<String> labels;

  const ReportAxis({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = TextStyle(fontSize: 11, color: colors.textHint);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final l in labels) Text(l, style: style)],
        ),
      ),
    );
  }
}

/// Axis with one equally wide label per bar (weekdays).
class ReportCellAxis extends StatelessWidget {
  final List<String> labels;

  const ReportCellAxis({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = TextStyle(fontSize: 11, color: colors.textHint);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            for (final l in labels)
              Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: style,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
