import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
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
        children: const [
          Shimmer(width: 44, height: 44, radius: 999),
          SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 130, height: 13, radius: 4),
                SizedBox(height: 7),
                Shimmer(width: 80, height: 11, radius: 4),
              ],
            ),
          ),
          Shimmer(width: 52, height: 22, radius: 999),
        ],
      ),
    );
  }
}
