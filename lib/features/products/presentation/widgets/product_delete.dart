import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// iOS action sheet confirm, then deletes the product through [ProductBloc].
/// Returns true when the product was deleted.
Future<bool> confirmDeleteProduct(
  BuildContext context,
  ProductData product,
) async {
  final productId = product.id;
  if (productId == null) return false;

  final bloc = context.read<ProductBloc>();
  final tr = context.tr;
  final name = productDisplayName(context, product);

  final confirmed = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text(tr.pcDeleteTitle(name)),
      message: Text(tr.pcDeleteBody),
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
          child: Text(tr.delete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(false),
        child: Text(tr.cancel),
      ),
    ),
  );

  if (confirmed != true) return false;

  HapticFeedback.mediumImpact();
  bloc.add(OnDeleteProduct(productId: productId));

  final result = await bloc.stream
      .firstWhere(
        (s) =>
            s.submitStatus == ProductSubmitStatus.success ||
            s.submitStatus == ProductSubmitStatus.failure,
      )
      .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);

  if (result.submitStatus == ProductSubmitStatus.success) {
    GlobalSnackBar.show(message: tr.pcDeleted, isInfo: true);
    return true;
  }

  GlobalSnackBar.show(
    message: result.submitError ?? tr.somethingWentWrong,
    isError: true,
    isAutoDismiss: false,
  );
  return false;
}
