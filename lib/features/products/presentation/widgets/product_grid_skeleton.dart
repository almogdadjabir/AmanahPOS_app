import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDims.rMd)),
              child: Container(color: context.appColors.border),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDims.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: double.infinity, height: 12, radius: 4),
                SizedBox(height: 6),
                Shimmer(width: 60, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: const [
          Shimmer(width: 56, height: 56, radius: AppDims.rSm),
          SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 140, height: 13, radius: 4),
                SizedBox(height: 7),
                Shimmer(width: 70, height: 13, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}