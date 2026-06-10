import 'dart:ui' as ui;

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class SaleStatCard extends StatelessWidget {
  const SaleStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.labelColor,
    required this.icon,
    this.forceValueLtr = false,
  });

  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final Color labelColor;
  final IconData icon;
  final bool forceValueLtr;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final displayLabel = locale == 'ar' ? label : label.toUpperCase();

    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
      style: AppTextStyles.bs400(context).copyWith(
        color: valueColor,
        fontWeight: FontWeight.w900,
        fontSize: 18,
        height: 1.1,
        letterSpacing: -0.25,
      ),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: valueColor.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s3,
            vertical: AppDims.s2 + 2,
          ),
          child: Row(
            children: [
              SaleStatIconBox(icon: icon, color: valueColor),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: labelColor,
                        fontSize: 9,
                        letterSpacing: locale == 'ar' ? 0 : 0.7,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    forceValueLtr
                        ? Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: valueText,
                          )
                        : valueText,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SaleStatIconBox extends StatelessWidget {
  const SaleStatIconBox({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
