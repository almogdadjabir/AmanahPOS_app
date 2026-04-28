import 'package:amana_pos/features/business/presentation/widgets/add_business_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';


class BusinessEmptyView extends StatelessWidget {
  const BusinessEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: context.appColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_mall_directory_rounded,
                  size: 36, color: context.appColors.primary),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              'No businesses yet',
              style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              'Create your first business to get started.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDims.s5),
            FilledButton.icon(
              onPressed: () => showAddBusinessSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s5, vertical: AppDims.s3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add Business',
                style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

