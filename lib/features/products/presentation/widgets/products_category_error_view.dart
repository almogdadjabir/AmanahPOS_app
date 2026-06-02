import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsCategoryErrorView extends StatelessWidget {
  final String? message;
  final String categoryId;
  const ProductsCategoryErrorView(
      {super.key, this.message, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context
          .read<CategoryBloc>()
          .add(OnLoadCategoryProducts(categoryId: categoryId)),
    );
  }
}
