import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteCategorySheet(
    BuildContext context, {
      required CategoryData category,
    }) {
  final categoryBloc = context.read<CategoryBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: categoryBloc,
      child: _DeleteCategorySheet(category: category),
    ),
  );
}

class _DeleteCategorySheet extends StatelessWidget {
  final CategoryData category;

  const _DeleteCategorySheet({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final categoryName = category.name?.trim();
    final displayName = categoryName?.isNotEmpty == true
        ? categoryName!
        : tr.category;

    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();

          GlobalSnackBar.show(
            message: context.tr.categoryDeletedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == CategorySubmitStatus.failure) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s4,
            AppDims.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(color: colors.border),

              const SizedBox(height: AppDims.s4),

              _DangerIcon(),

              const SizedBox(height: AppDims.s3),

              Text(
                tr.deleteCategoryTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),

              const SizedBox(height: AppDims.s2),

              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDims.s4,
                ),
                child: Text(
                  tr.deleteCategoryMessage(displayName),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: AppDims.s5),

              _DeleteActions(category: category),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final Color color;

  const _SheetHandle({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const SizedBox(
        width: 36,
        height: 4,
      ),
    );
  }
}

class _DangerIcon extends StatelessWidget {
  const _DangerIcon();

  @override
  Widget build(BuildContext context) {
    final dangerColor = context.appColors.danger;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dangerColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          SolarIconsOutline.trashBinTrash,
          size: 30,
          color: dangerColor,
        ),
      ),
    );
  }
}

class _DeleteActions extends StatelessWidget {
  final CategoryData category;

  const _DeleteActions({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocSelector<CategoryBloc, CategoryState, CategorySubmitStatus>(
      selector: (state) => state.submitStatus,
      builder: (context, submitStatus) {
        final isLoading = submitStatus == CategorySubmitStatus.loading;

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDims.s3,
                  ),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
                child: Text(
                  tr.cancel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppDims.s3),

            Expanded(
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () {
                  final categoryId = category.id?.trim();

                  if (categoryId == null || categoryId.isEmpty) {
                    GlobalSnackBar.show(
                      message: context.tr.invalidCategory,
                      isError: true,
                    );
                    return;
                  }

                  context.read<CategoryBloc>().add(
                    OnDeleteCategory(categoryId: categoryId),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.danger,
                  disabledBackgroundColor: colors.border,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDims.s3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    tr.delete,
                    key: const ValueKey('delete-label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}