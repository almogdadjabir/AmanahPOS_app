import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteProductSheet(BuildContext context, {required ProductData product}) {
  final productBloc = context.read<ProductBloc>();
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: productBloc,
      child: _DeleteProductSheet(product: product),
    ),
  );
}

class _DeleteProductSheet extends StatelessWidget {
  final ProductData product;
  const _DeleteProductSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final productName = product.name?.trim();
    final displayName = (productName?.isNotEmpty == true) ? productName! : tr.thisProduct;

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(message: tr.productDeletedSuccessfully, isInfo: true);
          return;
        }
        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<ProductBloc, ProductState, bool>(
        selector: (state) => state.submitStatus == ProductSubmitStatus.loading,
        builder: (context, isLoading) => AppDeactivateBottomSheet(
          title: tr.deleteProductTitle,
          description: tr.deleteProductMessage(displayName),
          icon: SolarIconsOutline.trashBinTrash,
          confirmText: tr.delete,
          confirmColor: colors.danger,
          isLoading: isLoading,
          onConfirm: () {
            final productId = product.id;
            if (productId == null || productId.isEmpty) {
              GlobalSnackBar.show(message: tr.invalidProduct, isError: true);
              return;
            }
            context.read<ProductBloc>().add(OnDeleteProduct(productId: productId));
          },
        ),
      ),
    );
  }
}
