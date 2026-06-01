import 'package:amana_pos/features/cart/presentation/qty_button.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

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
        borderRadius: BorderRadius.circular(AppDims.rSm),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.7),
        ),
      ),
      child: SizedBox(
        height: 34,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QtyButton(
              icon: SolarIconsOutline.minusCircle,
              onTap: onMinus,
            ),
            SizedBox(
              width: 30,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            QtyButton(
              icon: SolarIconsOutline.addCircle,
              onTap: onPlus,
            ),
          ],
        ),
      ),
    );
  }
}