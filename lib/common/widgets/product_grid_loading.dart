import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductGridLoading extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childAspectRatio;
  final EdgeInsets padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const ProductGridLoading({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.childAspectRatio = 0.76,
    this.padding = const EdgeInsets.all(AppDims.s4),
    this.mainAxisSpacing = AppDims.s3,
    this.crossAxisSpacing = AppDims.s3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) {
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppDims.rLg),
          ),
        );
      },
    );
  }
}
