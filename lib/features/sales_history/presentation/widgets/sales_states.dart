import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

/// Skeleton in the final layout: one day group of seven rows.
class SalesSkeleton extends StatelessWidget {
  const SalesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSkeleton(
      child: Padding(
        padding: const EdgeInsets.only(top: 26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 68,
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
                        Shimmer(width: 44, height: 44, radius: 12),
                        SizedBox(width: AppDims.s3),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Shimmer(width: 110, height: 15, radius: 6),
                              SizedBox(height: 8),
                              Shimmer(width: 160, height: 11, radius: 6),
                            ],
                          ),
                        ),
                        Shimmer(width: 70, height: 15, radius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum SalesStateTone { brand, danger }

/// Empty / error card: icon tile, title, one line, one action.
class SalesStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final SalesStateTone tone;

  const SalesStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.tone = SalesStateTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final danger = tone == SalesStateTone.danger;
    final (bg, fg) = danger
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
              const SizedBox(height: 20),
              // Empty: soft brand button. Error: solid brand button.
              if (danger)
                AppButton(
                  label: actionLabel,
                  onPressed: onAction,
                  size: AppButtonSize.large,
                )
              else
                Pressable(
                  onTap: onAction,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
