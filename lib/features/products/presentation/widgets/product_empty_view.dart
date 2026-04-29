import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductEmptyView extends StatelessWidget {
  final String title;
  final String message;
  const ProductEmptyView({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: context.appColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 36, color: context.appColors.primary),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            title,
            style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            message,
            style: AppTextStyles.bs400(context).copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
