import 'package:amana_pos/features/returns/presentation/widgets/step_btn.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReturnItemTile extends StatelessWidget {
  final SaleHistoryLineItem item;
  final bool isSelected;
  final int returnQty;
  final VoidCallback onToggle;
  final ValueChanged<int> onQtyChanged;

  const ReturnItemTile({super.key,
    required this.item,
    required this.isSelected,
    required this.returnQty,
    required this.onToggle,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxQty = item.quantity.toInt();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.danger.withValues(alpha: 0.4)
              : colors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: isSelected
            ? AppColors.dangerLight.withValues(alpha: 0.35)
            : colors.surface,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          highlightColor: AppColors.dangerLight.withValues(alpha: 0.5),
          splashColor: AppColors.dangerLight.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: AppDims.s3),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.danger : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color:
                      isSelected ? AppColors.danger : colors.border,
                      width: isSelected ? 0 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: AppDims.s3),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: AppTextStyles.bs200(context)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormat.moneyWithUnit(item.unitPrice)} × $maxQty sold',
                        style: AppTextStyles.sm100(context)
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s3),

                // Qty stepper or amount
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: isSelected
                      ? qtyStepper(
                    value: returnQty,
                    context: context,
                    max: maxQty,
                    onChanged: onQtyChanged,
                  )
                      : Text(
                    key: const ValueKey('amount'),
                    AppFormat.moneyWithUnit(item.subtotal),
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget qtyStepper({
    required BuildContext context,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
}){
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StepBtn(
          icon: Icons.remove_rounded,
          enabled: value > 1,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value - 1);
          },
          colors: colors,
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bs300(context)
                .copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        StepBtn(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value + 1);
          },
          colors: colors,
        ),
      ],
    );
  }
}
