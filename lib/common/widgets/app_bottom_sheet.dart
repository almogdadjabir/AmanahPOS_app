import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final String? logoAsset;

  const AppBottomSheet({super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s4,
            AppDims.s4,
            AppDims.s2,
          ),
          child: Row(
            children: [
              _SheetIcon(
                icon: icon,
                logoAsset: logoAsset,
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s2,
              AppDims.s4,
              AppDims.s4,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}


class _SheetIcon extends StatelessWidget {
  final IconData icon;
  final String? logoAsset;

  const _SheetIcon({
    required this.icon,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (logoAsset != null) {
      return Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: context.appColors.border),
        ),
        child: Image.asset(
          logoAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) {
            return Icon(
              icon,
              color: context.appColors.primary,
              size: 24,
            );
          },
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Icon(
        icon,
        color: context.appColors.primary,
        size: 23,
      ),
    );
  }
}
