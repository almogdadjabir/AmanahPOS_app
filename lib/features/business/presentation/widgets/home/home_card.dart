import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Home surface: radius 16, a 1px shadow in light, a hairline in dark.
class HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HomeCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: isDark ? Border.all(color: colors.border) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// Small section title above a card (sentence case, no tracking).
class HomeSectionLabel extends StatelessWidget {
  final String title;

  const HomeSectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(fontSize: 13, color: colors.textHint),
      ),
    );
  }
}

/// Hairline between rows, inset from the start.
class HomeHairline extends StatelessWidget {
  final double indent;

  const HomeHairline({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: indent,
      endIndent: 0,
      color: context.appColors.border,
    );
  }
}
