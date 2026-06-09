import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

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
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        child: ConstrainedBox(
          constraints: maxHeightFactor < 1.0
              ? BoxConstraints(maxHeight: screenHeight * maxHeightFactor)
              : const BoxConstraints(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetTitleBlock(
                        title: title,
                        subtitle: subtitle,
                      ),
                    ),

                    const SizedBox(width: AppDims.s2),

                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceSoft,
                        fixedSize: const Size(42, 42),
                        minimumSize: const Size(42, 42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                      ),
                      icon: Icon(
                        SolarIconsOutline.closeCircle,
                        size: 24,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SheetTitleBlock({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final subtitleText = subtitle?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs600(context).copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        if (subtitleText != null && subtitleText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitleText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
            prefixIcon: SolarIconsOutline.walletMoney,
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
            prefixIcon: SolarIconsOutline.moneyBag,
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
            prefixIcon: SolarIconsOutline.qrCode,
          ),
        ),

        const SizedBox(width: AppDims.s3),

        Expanded(
          child: _TextProductField(
            label: tr.fieldBarcode,
            controller: barcodeCtrl,
            focusNode: barcodeFocus,
            hint: '123456789',
            prefixIcon: SolarIconsOutline.scanner,
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
    final colors = context.appColors;

    return BlocSelector<ProductBloc, ProductState, ProductSubmitStatus>(
      selector: (state) => state.submitStatus,
      builder: (context, submitStatus) {
        final isLoading = submitStatus == ProductSubmitStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
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
                label,
                key: const ValueKey('label'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
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