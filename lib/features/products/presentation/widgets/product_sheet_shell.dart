import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ProductSheetShell extends StatelessWidget {
  final String title;
  final Widget body;
  final double maxHeightFactor;

  const ProductSheetShell({
    super.key,
    required this.title,
    required this.body,
    this.maxHeightFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: maxHeightFactor < 1.0
            ? BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        )
            : null,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDims.s3),

            // Drag handle
            Container(
              width:  36,
              height: 4,
              decoration: BoxDecoration(
                color:        colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDims.s4, AppDims.s4, AppDims.s4, 0),
              child: Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bs600(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width:  42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppDims.rSm),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 24, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDims.s4),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class ProductPriceRow extends StatelessWidget {
  final TextEditingController priceCtrl;
  final TextEditingController costCtrl;
  final FocusNode priceFocus;
  final FocusNode costFocus;
  final FocusNode? nextFocus;

  const ProductPriceRow({
    super.key,
    required this.priceCtrl,
    required this.costCtrl,
    required this.priceFocus,
    required this.costFocus,
    this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(label: 'Price', required: true),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: priceCtrl,
                focusNode: priceFocus,
                nextFocus: costFocus,
                hint: '1.50',
                prefixIcon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: ProductFormValidators.price,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(label: 'Cost Price'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: costCtrl,
                focusNode: costFocus,
                nextFocus: nextFocus,
                hint: '0.80',
                prefixIcon: Icons.price_check_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: ProductFormValidators.optionalPrice,
              ),
            ],
          ),
        ),
      ],
    );
  }
}



class ProductSkuBarcodeRow extends StatelessWidget {
  final TextEditingController skuCtrl;
  final TextEditingController barcodeCtrl;
  final FocusNode skuFocus;
  final FocusNode barcodeFocus;

  const ProductSkuBarcodeRow({
    super.key,
    required this.skuCtrl,
    required this.barcodeCtrl,
    required this.skuFocus,
    required this.barcodeFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(label: 'SKU'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: skuCtrl,
                focusNode:  skuFocus,
                nextFocus: barcodeFocus,
                hint: 'SKU-001',
                prefixIcon: Icons.qr_code_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(label: 'Barcode'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: barcodeCtrl,
                focusNode: barcodeFocus,
                hint: '123456789',
                prefixIcon: Icons.barcode_reader,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }
}



class ProductSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ProductSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == ProductSubmitStatus.loading;
        return SizedBox(
          width:  double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor:        context.appColors.primary,
              disabledBackgroundColor: context.appColors.border,
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
                : Text(
              label,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}


class ProductFormValidators {
  ProductFormValidators._();

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Product name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
    return null;
  }

  static String? optionalPrice(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
    return null;
  }
}