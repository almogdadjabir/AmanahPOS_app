import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductErrorView extends StatelessWidget {
  final String? message;
  const ProductErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () =>
          context.read<ProductBloc>().add(const OnProductInitial()),
    );
  }
}
