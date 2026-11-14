import 'package:amana_pos/features/cart/presentation/qty_button.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: AppDims.borderPill,
      ),
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QtyButton(icon: PhosphorIconsRegular.minus, onTap: onMinus),
            SizedBox(
              width: 22,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall!
                    .copyWith(color: colors.textPrimary)
                    .tabular,
              ),
            ),
            QtyButton(icon: PhosphorIconsRegular.plus, onTap: onPlus),
          ],
        ),
      ),
    );
  }
}
