import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class BusinessCardSkeleton extends StatelessWidget {
  const BusinessCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDims.s3),
          _Shimmer(width: 56, height: 56, radius: AppDims.rSm),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 140, height: 14, radius: 4),
                const SizedBox(height: 8),
                _Shimmer(width: 90, height: 11, radius: 4),
                const SizedBox(height: 6),
                _Shimmer(width: 110, height: 10, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  const _Shimmer({required this.width, required this.height, required this.radius});

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
