import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const TotalRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (isTotal
                ? AppTextStyles.bs600(context)
                : AppTextStyles.bs300(context))
                .copyWith(
              color: isTotal ? colors.primary : colors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: isTotal ? -0.6 : -0.2,
            ),
          ),
        ),
        const Spacer(),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: AppTextStyles.bs300(context).copyWith(
            color: isTotal ? colors.textPrimary : colors.textSecondary,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}