import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

/// Pinned header holding the period chips, on the page background.
class ReportChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;

  const ReportChipsHeaderDelegate({
    required this.child,
    required this.background,
  });

  @override
  double get minExtent => 54;

  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: background, child: child);

  @override
  bool shouldRebuild(covariant ReportChipsHeaderDelegate old) =>
      old.child != child || old.background != background;
}

/// Loading placeholder in the final layout: hero, then two cards.
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppSkeleton(
      child: Column(
        children: [
          Shimmer(width: double.infinity, height: 178, radius: 20),
          SizedBox(height: 12),
          Shimmer(width: double.infinity, height: 190, radius: 16),
          SizedBox(height: 12),
          Shimmer(width: double.infinity, height: 150, radius: 16),
        ],
      ),
    );
  }
}

/// Empty and error card: icon tile, title, text, optional primary button.
class ReportMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;

  const ReportMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  /// "No sales in this period".
  factory ReportMessageCard.empty(BuildContext context) => ReportMessageCard(
    icon: PhosphorIconsRegular.chartBar,
    title: context.tr.rpEmptyTitle,
    body: context.tr.rpEmptyBody,
  );

  factory ReportMessageCard.error(
    BuildContext context, {
    required VoidCallback onRetry,
  }) => ReportMessageCard(
    icon: PhosphorIconsRegular.wifiSlash,
    title: context.tr.rpErrorTitle,
    body: context.tr.shErrorBody,
    actionLabel: context.tr.shTryAgain,
    onAction: onRetry,
    danger: true,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = danger
        ? (colors.dangerContainer, colors.danger)
        : (colors.primaryContainer, colors.primary);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, danger ? 30 : 34, 28, 30),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: colors.border) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
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
            AppButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
