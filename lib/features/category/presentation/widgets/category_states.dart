import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

enum CategoryStateTone { brand, danger }

/// Empty / error card: tinted icon tile, title, one line of body, one
/// action (none when [actionLabel] or [onAction] is null, e.g. a cashier).
class CategoryStateCard extends StatelessWidget {
  final IconData icon;
  final CategoryStateTone tone;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool secondaryAction;

  const CategoryStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.tone = CategoryStateTone.brand,
    this.secondaryAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final (bg, fg) = tone == CategoryStateTone.danger
        ? (colors.dangerContainer, colors.danger)
        : (colors.primaryContainer, colors.primary);

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: fg),
              ),
              const SizedBox(height: AppDims.s4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleLarge!.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyMedium!.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDims.s5),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: secondaryAction
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton in the final layout of the category list.
class CategorySkeleton extends StatelessWidget {
  final int rows;
  const CategorySkeleton({super.key, this.rows = 6});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSkeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 44 + AppDims.s3,
                  color: colors.border,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.s4,
                  vertical: AppDims.s2,
                ),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Shimmer(width: 44, height: 44, radius: 11),
                      SizedBox(width: AppDims.s3),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer(width: 120, height: 15, radius: 6),
                            SizedBox(height: 8),
                            Shimmer(width: 150, height: 11, radius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
