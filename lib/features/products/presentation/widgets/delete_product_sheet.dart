import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteProductSheet(
    BuildContext context, {
      required ProductData product,
    }) {
  final productBloc = context.read<ProductBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: productBloc,
      child: _DeleteProductSheet(product: product),
    ),
  );
}

class _DeleteProductSheet extends StatelessWidget {
  final ProductData product;

  const _DeleteProductSheet({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final productName = product.name?.trim();
    final displayName = productName?.isNotEmpty == true
        ? productName!
        : tr.thisProduct;

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();

          GlobalSnackBar.show(
            message: context.tr.productDeletedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
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
              AppDims.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox(
                    width: 36,
                    height: 4,
                  ),
                ),

                const SizedBox(height: AppDims.s4),

                _DeleteIcon(),

                const SizedBox(height: AppDims.s4),

                Text(
                  tr.deleteProductTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: AppDims.s2),

                Text(
                  tr.deleteProductMessage(displayName),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: AppDims.s5),

                _DeleteActions(product: product),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteIcon extends StatelessWidget {
  const _DeleteIcon();

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
          color: dangerColor,
          size: 32,
        ),
      ),
    );
  }
}

class _DeleteActions extends StatelessWidget {
  final ProductData product;

  const _DeleteActions({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocSelector<ProductBloc, ProductState, ProductSubmitStatus>(
      selector: (state) => state.submitStatus,
      builder: (context, submitStatus) {
        final isLoading = submitStatus == ProductSubmitStatus.loading;

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
                child: Text(tr.cancel),
              ),
            ),

            const SizedBox(width: AppDims.s3),

            Expanded(
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () {
                  final productId = product.id;
                  if (productId == null || productId.isEmpty) {
                    GlobalSnackBar.show(
                      message: context.tr.invalidProduct,
                      isError: true,
                    );
                    return;
                  }

                  context.read<ProductBloc>().add(
                    OnDeleteProduct(productId: productId),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: colors.danger,
                  disabledBackgroundColor: colors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    tr.delete,
                    key: const ValueKey('delete-label'),
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