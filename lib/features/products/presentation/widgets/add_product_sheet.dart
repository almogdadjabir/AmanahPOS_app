import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Units the API accepts
const _kUnits = ['pcs', 'kg', 'g', 'l', 'ml', 'box', 'pack'];

void showAddProductSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProductBloc>(),
      child: const _AddProductSheet(),
    ),
  );
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _costFocus = FocusNode();
  final _descFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _barcodeFocus = FocusNode();

  CategoryData? _selectedCategory;
  String _selectedUnit = 'pcs';
  bool _trackInventory  = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _costCtrl.dispose();
    _descCtrl.dispose(); _skuCtrl.dispose(); _barcodeCtrl.dispose();
    _nameFocus.dispose(); _priceFocus.dispose(); _costFocus.dispose();
    _descFocus.dispose(); _skuFocus.dispose(); _barcodeFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      GlobalSnackBar.show(
        message: 'Please select a category',
        isError: true,
      );
      return;
    }

    context.read<ProductBloc>().add(OnAddProduct(
      dto: AddProductRequestDto(
        name: _nameCtrl.text.trim(),
        price: _priceCtrl.text.trim(),
        costPrice: _costCtrl.text.trim().isEmpty
            ? null
            : _costCtrl.text.trim(),
        category: _selectedCategory!.id!,
        unit: _selectedUnit,
        trackInventory: _trackInventory,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        sku: _skuCtrl.text.trim().isEmpty
            ? null
            : _skuCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty
            ? null
            : _barcodeCtrl.text.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: 'Product added successfully',
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
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDims.rXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const SizedBox(height: AppDims.s3),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),


              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                child: Row(
                  children: [
                    Text(
                      'New Product',
                      style: AppTextStyles.bs600(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 24,
                            color: context.appColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),


              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        FieldLabel(label: 'Product Name', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          focusNode:  _nameFocus,
                          nextFocus:  _priceFocus,
                          hint:        'Pepsi 330ml',
                          prefixIcon:  Icons.inventory_2_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Product name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s3),


                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FieldLabel(
                                      label: 'Price', required: true),
                                  const SizedBox(height: AppDims.s1),
                                  AppFormField(
                                    controller: _priceCtrl,
                                    focusNode:  _priceFocus,
                                    nextFocus:  _costFocus,
                                    hint:        '1.50',
                                    prefixIcon:  Icons.attach_money_rounded,
                                    keyboardType:
                                    TextInputType.numberWithOptions(
                                        decimal: true),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Price is required';
                                      }
                                      if (double.tryParse(v.trim()) ==
                                          null) {
                                        return 'Enter a valid price';
                                      }
                                      return null;
                                    },
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
                                    controller: _costCtrl,
                                    focusNode:  _costFocus,
                                    nextFocus:  _descFocus,
                                    hint:        '0.80',
                                    prefixIcon:
                                    Icons.price_check_rounded,
                                    keyboardType:
                                    TextInputType.numberWithOptions(
                                        decimal: true),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return null;
                                      }
                                      if (double.tryParse(v.trim()) ==
                                          null) {
                                        return 'Enter a valid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDims.s3),


                        FieldLabel(label: 'Category', required: true),
                        const SizedBox(height: AppDims.s1),
                        BlocBuilder<ProductBloc, ProductState>(
                          buildWhen: (prev, curr) =>
                          prev.categories != curr.categories,
                          builder: (context, state) {
                            return _CategoryPicker(
                              categories:       state.categories,
                              selected:         _selectedCategory,
                              onSelected: (c) =>
                                  setState(() => _selectedCategory = c),
                            );
                          },
                        ),
                        const SizedBox(height: AppDims.s3),


                        FieldLabel(label: 'Unit', required: true),
                        const SizedBox(height: AppDims.s2),
                        _UnitPicker(
                          selected:   _selectedUnit,
                          onSelected: (u) =>
                              setState(() => _selectedUnit = u),
                        ),


                        const SizedBox(height: AppDims.s4),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: context.appColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppDims.s2),
                              child: Text(
                                'OPTIONAL',
                                style: AppTextStyles.bs300(context)
                                    .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.appColors.textHint,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: context.appColors.border)),
                          ],
                        ),
                        const SizedBox(height: AppDims.s4),


                        FieldLabel(label: 'Description'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller:  _descCtrl,
                          focusNode:   _descFocus,
                          nextFocus:   _skuFocus,
                          hint:        'Product description',
                          prefixIcon:  Icons.notes_rounded,
                          maxLines:    3,
                        ),
                        const SizedBox(height: AppDims.s3),


                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FieldLabel(label: 'SKU'),
                                  const SizedBox(height: AppDims.s1),
                                  AppFormField(
                                    controller: _skuCtrl,
                                    focusNode:  _skuFocus,
                                    nextFocus:  _barcodeFocus,
                                    hint:        'SKU-001',
                                    prefixIcon:
                                    Icons.qr_code_rounded,
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
                                    controller: _barcodeCtrl,
                                    focusNode:  _barcodeFocus,
                                    hint:        '123456789',
                                    prefixIcon:
                                    Icons.barcode_reader,
                                    textInputAction: TextInputAction.done,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDims.s3),


                        _TrackInventoryToggle(
                          value:     _trackInventory,
                          onChanged: (v) =>
                              setState(() => _trackInventory = v),
                        ),
                        const SizedBox(height: AppDims.s5),


                        BlocBuilder<ProductBloc, ProductState>(
                          buildWhen: (prev, curr) =>
                          prev.submitStatus != curr.submitStatus,
                          builder: (context, state) {
                            final isLoading = state.submitStatus ==
                                ProductSubmitStatus.loading;
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.appColors.primary,
                                  disabledBackgroundColor:
                                  context.appColors.border,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppDims.rMd),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  'Add Product',
                                  style: AppTextStyles.bs600(context)
                                      .copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _CategoryPicker extends StatelessWidget {
  final List<CategoryData> categories;
  final CategoryData? selected;
  final ValueChanged<CategoryData> onSelected;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
        decoration: BoxDecoration(
          color: context.appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.layers_rounded,
                size: 18, color: context.appColors.textHint),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                selected?.name ?? 'Select a category',
                style: AppTextStyles.bs500(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected != null
                      ? context.appColors.textPrimary
                      : context.appColors.textHint,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: context.appColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDims.s3),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.appColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDims.s4),
              child: Text(
                'Select Category',
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDims.s5),
                child: Text(
                  'No categories available',
                  style: TextStyle(color: context.appColors.textHint),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, 0, AppDims.s4, AppDims.s5),
                itemCount: categories.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: context.appColors.border),
                itemBuilder: (_, i) {
                  final cat      = categories[i];
                  final isSelected = cat.id == selected?.id;
                  return ListTile(
                    onTap: () {
                      onSelected(cat);
                      Navigator.of(context).pop();
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: context.appColors.primaryContainer,
                        borderRadius:
                        BorderRadius.circular(AppDims.rSm),
                      ),
                      child: Icon(Icons.layers_rounded,
                          size: 18, color: context.appColors.primary),
                    ),
                    title: Text(
                      cat.name ?? '',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? context.appColors.primary
                            : context.appColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                        color: context.appColors.primary, size: 20)
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}



class _UnitPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _UnitPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDims.s2,
      runSpacing: AppDims.s2,
      children: _kUnits.map((unit) {
        final isSelected = unit == selected;
        return GestureDetector(
          onTap: () => onSelected(unit),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3, vertical: AppDims.s2),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.appColors.primary.withOpacity(0.10)
                  : context.appColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(
                color: isSelected
                    ? context.appColors.primary
                    : context.appColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              unit,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? context.appColors.primary
                    : context.appColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}



class _TrackInventoryToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TrackInventoryToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3, vertical: AppDims.s2),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_outlined,
              size: 18, color: context.appColors.textHint),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Inventory',
                  style: AppTextStyles.bs400(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  'Monitor stock levels for this product',
                  style: AppTextStyles.bs200(context).copyWith(
                    color: context.appColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: context.appColors.primary,
          ),
        ],
      ),
    );
  }
}