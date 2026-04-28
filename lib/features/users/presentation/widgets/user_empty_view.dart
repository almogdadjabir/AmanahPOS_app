import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class UserEmptyView extends StatelessWidget {
  const UserEmptyView({super.key});

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
              child: Icon(Icons.people_alt_rounded,
                  size: 36, color: context.appColors.primary),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              'No users yet',
              style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              'Add your first team member to get started.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs400(context).copyWith(
              fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
