import 'dart:ui' as ui;

import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class TotalRow extends StatelessWidget {
  const TotalRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final valueStyle = (isTotal
        ? AppTextStyles.bs600(context)
        : AppTextStyles.bs300(context))
        .copyWith(
      color: isTotal ? colors.primary : colors.textPrimary,
      fontWeight: FontWeight.w900,
      height: 1,
      letterSpacing: isTotal ? -0.6 : -0.2,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: AppTextStyles.bs300(context).copyWith(
              color: isTotal ? colors.textPrimary : colors.textSecondary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: valueStyle,
            ),
          ),
        ),
      ],
    );
  }
}