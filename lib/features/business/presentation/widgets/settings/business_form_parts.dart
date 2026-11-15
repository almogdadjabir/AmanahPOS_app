import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

/// 44pt nav bar with a back label on the start side and an optional action
/// (text or icon) on the end side. No title: the screen has a large title.
class BizNavBar extends StatelessWidget {
  final String backLabel;
  final Widget? trailing;

  const BizNavBar({super.key, required this.backLabel, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              scale: 1,
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      backLabel,
                      style: TextStyle(fontSize: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Text action for the nav bar ("Save"). Disabled when [onTap] is null.
class BizNavText extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  const BizNavText({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Pressable(
      onTap: busy ? null : onTap,
      scale: 1,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: onTap == null ? colors.disabled : colors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Form row label with the red required mark, like the customer form.
class BizRequiredLabel extends StatelessWidget {
  final String label;
  const BizRequiredLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            TextSpan(
              text: ' *',
              style: TextStyle(color: colors.danger),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontSize: 17, height: 1.3, color: colors.textPrimary),
      ),
    );
  }
}

/// Empty card: tinted icon tile, title, one line, one action.
class BizEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  const BizEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

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
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: colors.primary),
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
              const SizedBox(height: AppDims.s5),
              AppButton(label: actionLabel, onPressed: onAction),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton in the layout of the shops list.
class ShopsSkeleton extends StatelessWidget {
  final int rows;
  const ShopsSkeleton({super.key, this.rows = 3});

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
