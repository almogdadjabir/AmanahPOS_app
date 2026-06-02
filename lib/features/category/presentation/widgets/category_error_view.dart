import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryErrorView extends StatelessWidget {
  final String? message;
  const CategoryErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () =>
          context.read<CategoryBloc>().add(const OnCategoryInitial()),
    );
  }
}
