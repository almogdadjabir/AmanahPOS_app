import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SaleFooter extends StatelessWidget {
  final bool isLoadingMore, hasMore;
  const SaleFooter({super.key, required this.isLoadingMore, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDims.s4),
        child: Center(child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary))),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 14, color: colors.textHint),
            const SizedBox(width: 6),
            Text('All sales loaded',
                style: AppTextStyles.sm100(context)
                    .copyWith(color: colors.textHint)),
          ],
        ),
      );
    }
    return const SizedBox(height: AppDims.s4);
  }
}
