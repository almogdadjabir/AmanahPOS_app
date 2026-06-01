import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class WorkspaceSectionHeader extends StatelessWidget {
  const WorkspaceSectionHeader({
    super.key,
    required this.title,
    this.color,
  });

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final displayTitle = locale == 'ar' ? title : title.toUpperCase();
    final colors = context.appColors;
    final titleColor = color ?? colors.textSecondary.withValues(alpha: 0.82);

    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: AppTextStyles.bs300(context).copyWith(
              color: titleColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _SectionLine(color: colors.border),
        ),
      ],
    );
  }
}

class _SectionLine extends StatelessWidget {
  const _SectionLine({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            color.withValues(alpha: 0.60),
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: const SizedBox(height: 1),
    );
  }
}