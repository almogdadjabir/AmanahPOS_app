import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteCategorySheet(BuildContext context, {required CategoryData category}) {
  final categoryBloc = context.read<CategoryBloc>();
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: categoryBloc,
      child: _DeleteCategorySheet(category: category),
    ),
  );
}

class _DeleteCategorySheet extends StatelessWidget {
  final CategoryData category;
  const _DeleteCategorySheet({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final categoryName = category.name?.trim();
    final displayName = (categoryName?.isNotEmpty == true) ? categoryName! : tr.category;

    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(message: tr.categoryDeletedSuccessfully, isInfo: true);
          return;
        }
        if (state.submitStatus == CategorySubmitStatus.failure) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: state.submitError ?? tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<CategoryBloc, CategoryState, bool>(
        selector: (state) => state.submitStatus == CategorySubmitStatus.loading,
        builder: (context, isLoading) => AppDeactivateBottomSheet(
          title: tr.deleteCategoryTitle,
          description: tr.deleteCategoryMessage(displayName),
          icon: SolarIconsOutline.trashBinTrash,
          confirmText: tr.delete,
          confirmColor: colors.danger,
          isLoading: isLoading,
          onConfirm: () {
            final categoryId = category.id?.trim();
            if (categoryId == null || categoryId.isEmpty) {
              GlobalSnackBar.show(message: tr.invalidCategory, isError: true);
              return;
            }
            context.read<CategoryBloc>().add(OnDeleteCategory(categoryId: categoryId));
          },
        ),
      ),
    );
  }
}
