import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
      itemBuilder: (_, i) => _SkeletonTile(colors: colors)
          .animate(delay: Duration(milliseconds: i * 40))
          .shimmer(duration: 1200.ms, color: colors.border.withValues(alpha: 0.6)),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  final AppThemeColors colors;
  const _SkeletonTile({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 160,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  height: 11,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}