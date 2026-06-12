import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/returns/presentation/widgets/step_btn.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';

class ReturnItemTile extends StatelessWidget {
  final SaleHistoryLineItem item;
  final bool isSelected;
  final int returnQty;
  final VoidCallback onToggle;
  final ValueChanged<int> onQtyChanged;
  final bool compact;

  const ReturnItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.returnQty,
    required this.onToggle,
    required this.onQtyChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxQty = item.quantity.toInt();

    final hPad = compact ? AppDims.s3 : AppDims.s4;
    final vPad = compact ? AppDims.s2 : AppDims.s3;
    final checkSize = compact ? 18.0 : 22.0;
    final checkRadius = compact ? 6.0 : 7.0;
    final nameStyle = compact
        ? AppTextStyles.sm200(context).copyWith(fontWeight: FontWeight.w700)
        : AppTextStyles.bs200(context).copyWith(fontWeight: FontWeight.w700);
    final metaStyle = compact
        ? AppTextStyles.sm100(context).copyWith(color: colors.textSecondary)
        : AppTextStyles.sm100(context).copyWith(color: colors.textSecondary);
    final amountStyle = compact
        ? AppTextStyles.sm200(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          )
        : AppTextStyles.bs200(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          );

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 11 : 14),
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
          borderRadius: BorderRadius.circular(compact ? 10 : 13),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            highlightColor: AppColors.dangerLight.withValues(alpha: 0.5),
            splashColor: AppColors.dangerLight.withValues(alpha: 0.3),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Row(
                children: [
                  // Animated checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    width: checkSize,
                    height: checkSize,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.danger : colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(checkRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.danger : colors.border,
                        width: isSelected ? 0 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            SolarIconsOutline.checkSquare,
                            color: Colors.white,
                            size: compact ? 11 : 14,
                          )
                        : null,
                  ),
                  SizedBox(width: compact ? AppDims.s2 : AppDims.s3),

                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: nameStyle,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: item.productName.contentDirection,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppFormat.moneyWithUnit(item.unitPrice)} × $maxQty ${context.tr.sold}',
                          style: metaStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? AppDims.s2 : AppDims.s3),

                  // Qty stepper or amount
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isSelected
                        ? _qtyStepper(context, returnQty, maxQty, colors)
                        : Text(
                            key: const ValueKey('amount'),
                            AppFormat.moneyWithUnit(item.subtotal),
                            style: amountStyle,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyStepper(
    BuildContext context,
    int value,
    int max,
    AppThemeColors colors,
  ) {
    return Row(
      key: const ValueKey('stepper'),
      mainAxisSize: MainAxisSize.min,
      children: [
        StepBtn(
          icon: Icons.remove_rounded,
          enabled: value > 1,
          onTap: () {
            HapticFeedback.selectionClick();
            onQtyChanged(value - 1);
          },
          colors: colors,
        ),
        SizedBox(
          width: compact ? 28 : 36,
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            style: compact
                ? AppTextStyles.sm200(context).copyWith(
                    fontWeight: FontWeight.w900,
                  )
                : AppTextStyles.bs300(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
          ),
        ),
        StepBtn(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () {
            HapticFeedback.selectionClick();
            onQtyChanged(value + 1);
          },
          colors: colors,
        ),
      ],
    );
  }
}
