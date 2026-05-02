import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/category_chip.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.select<ProductBloc, List<CategoryData>>(
          (bloc) => bloc.state.categories,
    );

    final selectedCategoryId = context.select<PosBloc, String?>(
          (bloc) => bloc.state.selectedCategoryId,
    );

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 54,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s2,
          AppDims.s4,
          AppDims.s2,
        ),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppDims.s2),
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              key: const ValueKey('pos_category_all'),
              label: 'All',
              icon: Icons.grid_view_rounded,
              selected: selectedCategoryId == null,
              onTap: () {
                context.read<PosBloc>().add(
                  const PosCategoryChanged(null),
                );
              },
            );
          }

          final category = categories[index - 1];
          final categoryId = category.id;

          return CategoryChip(
            key: ValueKey('pos_category_${categoryId ?? index}'),
            label: category.name?.trim().isNotEmpty == true
                ? category.name!.trim()
                : 'Category',
            icon: Icons.layers_rounded,
            selected: selectedCategoryId == categoryId,
            onTap: () {
              context.read<PosBloc>().add(
                PosCategoryChanged(categoryId),
              );
            },
          );
        },
      ),
    );
  }
}