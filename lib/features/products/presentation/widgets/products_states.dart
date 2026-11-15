import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

/// Skeleton in the final layout: grouped rows, or grid tiles.
class ProductsSkeleton extends StatelessWidget {
  final bool grid;

  const ProductsSkeleton({super.key, this.grid = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (grid) {
      return AppSkeleton(
        child: Wrap(
          spacing: AppDims.s3,
          runSpacing: AppDims.s3,
          children: [
            for (var i = 0; i < 4; i++)
              LayoutBuilder(
                builder: (context, _) {
                  final w =
                      (MediaQuery.sizeOf(context).width -
                          AppDims.s4 * 2 -
                          AppDims.s3) /
                      2;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: AppDims.borderLg,
                      border: Border.all(color: colors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(
                            width: w - 20,
                            height: (w - 20) / 1.25,
                            radius: 12,
                          ),
                          const SizedBox(height: 10),
                          const Shimmer(width: 90, height: 14, radius: 6),
                          const SizedBox(height: 6),
                          const Shimmer(width: 56, height: 11, radius: 6),
                          const SizedBox(height: 8),
                          const Shimmer(width: 64, height: 16, radius: 6),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    return AppSkeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < 6; i++) ...[
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
                            Shimmer(width: 150, height: 15, radius: 6),
                            SizedBox(height: 8),
                            Shimmer(width: 90, height: 11, radius: 6),
                          ],
                        ),
                      ),
                      Shimmer(width: 44, height: 15, radius: 6),
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

enum ProductsStateTone { brand, danger }

/// Zero state card: icon tile, title, one line, optional single action.
class ProductsStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ProductsStateTone tone;

  const ProductsStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.tone = ProductsStateTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final (bg, fg) = tone == ProductsStateTone.danger
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
              const SizedBox(height: 16),
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
                const SizedBox(height: 20),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: tone == ProductsStateTone.danger
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  size: AppButtonSize.large,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
