import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

class InventoryLoadingView extends StatelessWidget {
  const InventoryLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, _) => stockSkeleton(context),
    );
  }


  Widget stockSkeleton(BuildContext context){
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: [
          const Shimmer(width: 54, height: 54, radius: AppDims.rMd),
          const SizedBox(width: AppDims.s3),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 150, height: 13, radius: 4),
                SizedBox(height: 7),
                Shimmer(width: 100, height: 11, radius: 4),
                SizedBox(height: 7),
                Shimmer(width: 70, height: 18, radius: 999),
              ],
            ),
          ),
          const Shimmer(width: 50, height: 42, radius: AppDims.rSm),
        ],
      ),
    );
  }
}