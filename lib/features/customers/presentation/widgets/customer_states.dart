import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

enum CustomerStateTone { brand, danger }

/// Empty / error card: tinted tile, title, body, optional brand button.
class CustomerStateCard extends StatelessWidget {
  final IconData icon;
  final CustomerStateTone tone;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CustomerStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.tone = CustomerStateTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final (bg, fg) = tone == CustomerStateTone.danger
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
                AppButton(label: actionLabel!, onPressed: onAction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton in the final layout of the customer list: round avatar, name
/// line (44%) and phone line (62%).
class CustomerSkeleton extends StatelessWidget {
  final int rows;
  const CustomerSkeleton({super.key, this.rows = 6});

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
        child: LayoutBuilder(
          builder: (context, c) {
            final textWidth = c.maxWidth - 32 - 44 - 12;
            return Column(
              children: [
                for (var i = 0; i < rows; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 68,
                      color: colors.border,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        children: [
                          const Shimmer(width: 44, height: 44, radius: 22),
                          const SizedBox(width: AppDims.s3),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Shimmer(
                                  width: textWidth * 0.44,
                                  height: 15,
                                  radius: 8,
                                ),
                                const SizedBox(height: 8),
                                Shimmer(
                                  width: textWidth * 0.62,
                                  height: 11,
                                  radius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
