import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

/// Skeleton for the grouped product list while products load.
class ProductListLoading extends StatelessWidget {
  final int itemCount;

  const ProductListLoading({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSkeleton(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4,
          0,
          AppDims.s4,
          AppDims.s6,
        ),
        itemCount: itemCount,
        itemBuilder: (_, index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.vertical(
                top: index == 0
                    ? const Radius.circular(AppDims.rLg)
                    : Radius.zero,
                bottom: index == itemCount - 1
                    ? const Radius.circular(AppDims.rLg)
                    : Radius.zero,
              ),
            ),
            child: const SizedBox(
              height: 60,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.s3,
                  vertical: AppDims.s2 + 2,
                ),
                child: Row(
                  children: [
                    Shimmer(width: 40, height: 40, radius: 10),
                    SizedBox(width: AppDims.s3),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(width: 140, height: 14, radius: 6),
                          SizedBox(height: 6),
                          Shimmer(width: 80, height: 10, radius: 5),
                        ],
                      ),
                    ),
                    Shimmer(width: 44, height: 14, radius: 6),
                    SizedBox(width: AppDims.s3),
                    Shimmer(width: 32, height: 32, radius: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
