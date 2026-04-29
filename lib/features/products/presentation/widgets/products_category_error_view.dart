import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsCategoryErrorView extends StatelessWidget {
  final String? message;
  final String categoryId;
  const ProductsCategoryErrorView(
      {super.key, required this.message, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 40, color: context.appColors.textHint),
          const SizedBox(height: AppDims.s3),
          Text(
            message ?? 'Failed to load products',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 13,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          OutlinedButton.icon(
            onPressed: () => context.read<CategoryBloc>().add(
                OnLoadCategoryProducts(categoryId: categoryId)),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}