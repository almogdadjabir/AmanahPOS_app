import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/app_amount.dart';
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
    final text = Theme.of(context).textTheme;

    final labelStyle = isTotal
        ? text.titleMedium!.copyWith(color: colors.textPrimary)
        : text.bodyMedium!.copyWith(color: colors.textSecondary, fontSize: 15);
    final valueStyle = isTotal
        ? text.headlineMedium!.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          )
        : text.bodyMedium!.copyWith(color: colors.textSecondary, fontSize: 15);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Flexible(
          child: AppAmount(
            value: value,
            unit: AppFormat.currency,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
