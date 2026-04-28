import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: [
          _Shimmer(width: 44, height: 44, radius: 999),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 130, height: 13, radius: 4),
                const SizedBox(height: 7),
                _Shimmer(width: 80, height: 11, radius: 4),
              ],
            ),
          ),
          _Shimmer(width: 52, height: 22, radius: 999),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: context.appColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
