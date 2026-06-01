import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/delete_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/edit_product_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductActionsView extends StatelessWidget {
  final ProductData product;
  final bool showStock;

  const ProductActionsView({
    super.key,
    required this.product,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: SolarIconsOutline.penNewSquare,
            label: tr.edit,
            color: colors.primary,
            onTap: () {
              showEditProductSheet(context, product: product);
            },
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _ActionButton(
            icon: SolarIconsOutline.trashBinTrash,
            label: tr.delete,
            color: const Color(0xFFDC2626),
            isDanger: true,
            onTap: () {
              showDeleteProductSheet(context, product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDanger;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final backgroundColor = isDanger
        ? color.withValues(alpha: 0.07)
        : colors.surface;

    final borderColor = isDanger
        ? color.withValues(alpha: 0.22)
        : colors.border;

    final textColor = isDanger ? color : colors.textPrimary;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(color: borderColor),
            ),
            child: SizedBox(
              height: 82,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s2,
                  vertical: AppDims.s3,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppDims.rSm),
                      ),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          icon,
                          color: color,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs300(context).copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}