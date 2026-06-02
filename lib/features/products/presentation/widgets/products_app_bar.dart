import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/feature_sliver_app_bar.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductsAppBar extends StatelessWidget {
  const ProductsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return FeatureSliverAppBar(
      title: tr.catAppBarProducts,
      actionLabel: tr.addProduct,
      onAction: () => showAddProductSheet(context),
      additionalActions: [
        BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, curr) => prev.isGrid != curr.isGrid,
          builder: (context, state) {
            return IconButton(
              tooltip: state.isGrid ? tr.showList : tr.showGrid,
              onPressed: () {
                context.read<ProductBloc>().add(
                      const OnToggleProductLayout(),
                    );
              },
              icon: Icon(
                state.isGrid
                    ? SolarIconsOutline.list
                    : SolarIconsOutline.widget,
                color: context.appColors.textPrimary,
                size: 22,
              ),
            );
          },
        ),
      ],
    );
  }
}
