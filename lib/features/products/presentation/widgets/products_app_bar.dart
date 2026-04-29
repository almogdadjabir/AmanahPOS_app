import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsAppBar extends StatelessWidget {
  const ProductsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      title: Text(
        'Products',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w800,
          color: context.appColors.textPrimary,
        ),
      ),
      actions: [
        BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, curr) => prev.isGrid != curr.isGrid,
          builder: (context, state) {
            return IconButton(
              onPressed: () => context
                  .read<ProductBloc>()
                  .add(const OnToggleProductLayout()),
              icon: Icon(
                state.isGrid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                color: context.appColors.textPrimary,
              ),
            );
          },
        ),
      ],
    );
  }
}