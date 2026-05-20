// lib/features/products/presentation/widgets/products_app_bar.dart

import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductsAppBar extends StatelessWidget {
  const ProductsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: context.appColors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Products',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: context.appColors.textPrimary,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => showAddProductSheet(context),
          icon: Icon(SolarIconsOutline.addCircle,
              size: 18, color: context.appColors.primary),
          label: Text(
            'Add product',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.primary,
            ),
          ),
        ),

        // Grid / list toggle.
        BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, curr) => prev.isGrid != curr.isGrid,
          builder: (context, state) {
            return IconButton(
              tooltip: state.isGrid ? 'Show list' : 'Show grid',
              onPressed: () {
                context.read<ProductBloc>().add(
                  const OnToggleProductLayout(),
                );
              },
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