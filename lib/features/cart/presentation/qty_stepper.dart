import 'package:amana_pos/features/cart/presentation/qty_button.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const QtyStepper({super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QtyButton(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          QtyButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}