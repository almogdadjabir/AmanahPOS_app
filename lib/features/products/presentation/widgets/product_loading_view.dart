import 'package:amana_pos/features/products/presentation/widgets/product_grid_skeleton.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';


class ProductLoadingView extends StatelessWidget {
  final bool isGrid;
  const ProductLoadingView({super.key, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppDims.s4),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppDims.s3,
          mainAxisSpacing: AppDims.s3,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => ProductGridSkeleton(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, _) => ProductListSkeleton(),
    );
  }
}