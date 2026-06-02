import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
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
          const Shimmer(width: 56, height: 56, radius: AppDims.rSm),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: 140, height: 14, radius: 4),
                SizedBox(height: 8),
                Shimmer(width: 90, height: 11, radius: 4),
                SizedBox(height: 6),
                Shimmer(width: 110, height: 10, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
        ],
      ),
    );
  }
}
