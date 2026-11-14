import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class ProductSheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final double maxHeightFactor;

  const ProductSheetShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.maxHeightFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: title,
      subtitle: subtitle,
      maxHeightFactor: maxHeightFactor,
      showGrabber: false,
      child: body,
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
    final tr = context.tr;

    return Row(
      children: [
        Expanded(
          child: _PriceField(
            label: tr.price,
            controller: priceCtrl,
            focusNode: priceFocus,
            nextFocus: costFocus,
            hint: '1.50',
            prefixIcon: PhosphorIconsRegular.wallet,
            isRequired: true,
            validator: (value) => ProductFormValidators.price(context, value),
          ),
        ),

        const SizedBox(width: AppDims.s3),

        Expanded(
          child: _PriceField(
            label: tr.fieldCostPrice,
            controller: costCtrl,
            focusNode: costFocus,
            nextFocus: nextFocus,
            hint: '0.80',
            prefixIcon: PhosphorIconsRegular.coins,
            validator: (value) {
              return ProductFormValidators.optionalPrice(context, value);
            },
          ),
        ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final IconData prefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;

  const _PriceField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.prefixIcon,
    this.nextFocus,
    this.isRequired = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(
          label: label,
          required: isRequired,
        ),
        const SizedBox(height: AppDims.s1),
        AppFormField(
          controller: controller,
          focusNode: focusNode,
          nextFocus: nextFocus,
          hint: hint,
          prefixIcon: prefixIcon,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
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
    final tr = context.tr;

    return Row(
      children: [
        Expanded(
          child: _TextProductField(
            label: tr.fieldSku,
            controller: skuCtrl,
            focusNode: skuFocus,
            nextFocus: barcodeFocus,
            hint: 'SKU-001',
            prefixIcon: PhosphorIconsRegular.qrCode,
          ),
        ),

        const SizedBox(width: AppDims.s3),

        Expanded(
          child: _TextProductField(
            label: tr.fieldBarcode,
            controller: barcodeCtrl,
            focusNode: barcodeFocus,
            hint: '123456789',
            prefixIcon: PhosphorIconsRegular.scan,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}

class _TextProductField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _TextProductField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.prefixIcon,
    this.nextFocus,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label),
        const SizedBox(height: AppDims.s1),
        AppFormField(
          controller: controller,
          focusNode: focusNode,
          nextFocus: nextFocus,
          hint: hint,
          prefixIcon: prefixIcon,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
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
    return BlocSelector<ProductBloc, ProductState, ProductSubmitStatus>(
      selector: (state) => state.submitStatus,
      builder: (context, submitStatus) {
        final isLoading = submitStatus == ProductSubmitStatus.loading;

        return AppButton.wide(
          label: label,
          isLoading: isLoading,
          onPressed: isLoading ? null : onPressed,
        );
      },
    );
  }
}

class ProductFormValidators {
  ProductFormValidators._();

  static String? name(BuildContext context, String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return context.tr.productNameRequired;
    }

    if (text.length < 2) {
      return context.tr.nameMustBeAtLeast2Characters;
    }

    return null;
  }

  static String? price(BuildContext context, String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return context.tr.priceRequired;
    }

    if (double.tryParse(text) == null) {
      return context.tr.enterValidPrice;
    }

    return null;
  }

  static String? optionalPrice(BuildContext context, String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    if (double.tryParse(text) == null) {
      return context.tr.enterValidPrice;
    }

    return null;
  }
}