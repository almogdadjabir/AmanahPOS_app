import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showDeleteProductSheet(
    BuildContext context, {
      required ProductData product,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProductBloc>(),
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

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop(); // sheet
          Navigator.of(context).maybePop(); // detail screen

          GlobalSnackBar.show(
            message: 'Product deleted successfully',
            isInfo: true,
          );
        }

        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s4,
            AppDims.s4,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppDims.s4),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: AppDims.s4),
              Text(
                'Delete Product?',
                style: AppTextStyles.bs600(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                'Are you sure you want to delete "${product.name ?? 'this product'}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDims.s5),
              BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (prev, curr) =>
                prev.submitStatus != curr.submitStatus,
                builder: (context, state) {
                  final isLoading =
                      state.submitStatus == ProductSubmitStatus.loading;

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDims.rMd),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () {
                            final productId = product.id;
                            if (productId == null) {
                              GlobalSnackBar.show(
                                message: 'Invalid product',
                                isError: true,
                              );
                              return;
                            }

                            context.read<ProductBloc>().add(
                              OnDeleteProduct(
                                productId: productId,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: const Color(0xFFDC2626),
                            disabledBackgroundColor: colors.border,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDims.rMd),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Delete'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}