import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class WorkspaceSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const WorkspaceSectionHeader({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      spacing: AppDims.s3,
      children: [
        Text(
          title,
          style: AppTextStyles.bs300(context).copyWith(
            color: color ?? colors.textSecondary.withValues(alpha: 0.82),
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
          ),
        ),

        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.border.withValues(alpha: 0.60),
                  colors.border.withValues(alpha: 0.25),
                  colors.border.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
