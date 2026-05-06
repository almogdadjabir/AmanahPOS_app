import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkspaceActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const WorkspaceActionCard({super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: 23,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}