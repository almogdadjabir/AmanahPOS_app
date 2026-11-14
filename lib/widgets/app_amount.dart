import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Amount with a small trailing unit. Tabular figures, always left-to-right
/// so digits never reorder inside Arabic text.
class AppAmount extends StatelessWidget {
  final String value;
  final String? unit;
  final TextStyle style;
  final Color? unitColor;
  final TextAlign textAlign;

  const AppAmount({
    super.key,
    required this.value,
    required this.style,
    this.unit,
    this.unitColor,
    this.textAlign = TextAlign.end,
  });

  @override
  Widget build(BuildContext context) {
    final base = style.tabular;
    final unitStyle = base.copyWith(
      fontSize: (base.fontSize ?? 16) * 0.58,
      fontWeight: FontWeight.w500,
      color: unitColor ?? base.color?.withValues(alpha: 0.6),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value, style: base),
            if (unit != null) ...[
              const TextSpan(text: ' '),
              TextSpan(text: unit, style: unitStyle),
            ],
          ],
        ),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );
  }
}
