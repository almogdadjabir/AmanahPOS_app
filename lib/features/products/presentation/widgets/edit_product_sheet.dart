import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_inventory_alerts_section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kProductUnits = ['pcs', 'kg', 'g', 'l', 'ml', 'box', 'pack'];

void showEditProductSheet(
    BuildContext context, {
      required ProductData product,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProductBloc>(),
      child: _EditProductSheet(product: product),
    ),
  );
}

class _EditProductSheet extends StatefulWidget {
  final ProductData product;

  const _EditProductSheet({
    required this.product,
  });

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _expiryAlertCtrl;

  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _costFocus = FocusNode();
  final _descFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _barcodeFocus = FocusNode();
  final _minStockFocus = FocusNode();
  final _expiryAlertFocus = FocusNode();

  CategoryData? _selectedCategory;
  String _selectedUnit = 'pcs';
  bool _trackInventory = true;

  String? get _effectiveCategoryId {
    final selectedId = _selectedCategory?.id;
    if (selectedId != null && selectedId.trim().isNotEmpty) {
      return selectedId;
    }

    final productCategoryId = widget.product.category;
    if (productCategoryId != null && productCategoryId.trim().isNotEmpty) {
      return productCategoryId;
    }

    return null;
  }

  String? get _effectiveCategoryName {
    final selectedName = _selectedCategory?.name;
    if (selectedName != null && selectedName.trim().isNotEmpty) {
      return selectedName;
    }

    final productCategoryName = widget.product.categoryName;
    if (productCategoryName != null && productCategoryName.trim().isNotEmpty) {
      return productCategoryName;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    _nameCtrl = TextEditingController(text: p.name ?? '');
    _priceCtrl = TextEditingController(text: p.price?.toString() ?? '');
    _costCtrl = TextEditingController(text: p.costPrice?.toString() ?? '');
    _descCtrl = TextEditingController(text: p.description ?? '');
    _skuCtrl = TextEditingController(text: p.sku ?? '');
    _barcodeCtrl = TextEditingController(text: p.barcode ?? '');
    _minStockCtrl = TextEditingController(
      text: widget.product.minStockLevel?.toString() ?? '',
    );

    _expiryAlertCtrl = TextEditingController();

    _selectedUnit = p.unit?.trim().isNotEmpty == true ? p.unit! : 'pcs';
    _trackInventory = p.trackInventory ?? true;


    final categories = context.read<ProductBloc>().state.categories;
    final matchedCategories = categories
        .where((c) => c.id == p.category)
        .toList(growable: false);

    _selectedCategory = matchedCategories.isEmpty ? null : matchedCategories.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _descCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();

    _nameFocus.dispose();
    _priceFocus.dispose();
    _costFocus.dispose();
    _descFocus.dispose();
    _skuFocus.dispose();
    _barcodeFocus.dispose();
    _minStockCtrl.dispose();
    _expiryAlertCtrl.dispose();
    _minStockFocus.dispose();
    _expiryAlertFocus.dispose();

    super.dispose();
  }

  void _submit() {
    final productId = widget.product.id;

    if (productId == null) {
      GlobalSnackBar.show(
        message: 'Invalid product',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final categoryId = _effectiveCategoryId;

    if (categoryId == null || categoryId.trim().isEmpty) {
      GlobalSnackBar.show(
        message: 'Please select a category',
        isError: true,
      );
      return;
    }

    context.read<ProductBloc>().add(
      OnUpdateProduct(
        productId: productId,
        dto: UpdateProductRequestDto(
          name: _nameCtrl.text.trim(),
          price: _priceCtrl.text.trim(),
          costPrice: _costCtrl.text.trim().isEmpty
              ? null
              : _costCtrl.text.trim(),
          category: categoryId,
          unit: _selectedUnit,
          trackInventory: _trackInventory,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim().isEmpty
              ? null
              : _barcodeCtrl.text.trim(),
          minStockLevel: _minStockCtrl.text.trim().isEmpty
              ? null
              : _minStockCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: 'Product updated successfully',
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.90,
          ),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDims.s3),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Edit Product',
                      style: AppTextStyles.bs600(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: context.appColors.textSecondary,
                        ),
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
                          focusNode: _nameFocus,
                          nextFocus: _priceFocus,
                          hint: 'Pepsi 330ml',
                          prefixIcon: Icons.inventory_2_outlined,
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
                                  FieldLabel(label: 'Price', required: true),
                                  const SizedBox(height: AppDims.s1),
                                  AppFormField(
                                    controller: _priceCtrl,
                                    focusNode: _priceFocus,
                                    nextFocus: _costFocus,
                                    hint: '1.50',
                                    prefixIcon: Icons.attach_money_rounded,
                                    keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Price is required';
                                      }
                                      if (double.tryParse(v.trim()) == null) {
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
                                    focusNode: _costFocus,
                                    nextFocus: _descFocus,
                                    hint: '0.80',
                                    prefixIcon: Icons.price_check_rounded,
                                    keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return null;
                                      }
                                      if (double.tryParse(v.trim()) == null) {
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
                          buildWhen: (prev, curr) => prev.categories != curr.categories,
                          builder: (context, state) {
                            return _EditCategoryPicker(
                              categories: state.categories,
                              selected: _selectedCategory,
                              fallbackSelectedId: _effectiveCategoryId,
                              fallbackSelectedName: _effectiveCategoryName,
                              onSelected: (category) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: 'Unit', required: true),
                        const SizedBox(height: AppDims.s2),
                        _EditUnitPicker(
                          selected: _selectedUnit,
                          onSelected: (unit) {
                            setState(() {
                              _selectedUnit = unit;
                            });
                          },
                        ),

                        const SizedBox(height: AppDims.s4),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: context.appColors.border),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDims.s2,
                              ),
                              child: Text(
                                'OPTIONAL',
                                style: AppTextStyles.bs300(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.appColors.textHint,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: context.appColors.border),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDims.s4),

                        FieldLabel(label: 'Description'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _descCtrl,
                          focusNode: _descFocus,
                          nextFocus: _skuFocus,
                          hint: 'Product description',
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
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
                                    focusNode: _skuFocus,
                                    nextFocus: _barcodeFocus,
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
                                    controller: _barcodeCtrl,
                                    focusNode: _barcodeFocus,
                                    hint: '123456789',
                                    prefixIcon: Icons.barcode_reader,
                                    textInputAction: TextInputAction.done,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDims.s3),

                        _EditTrackInventoryToggle(
                          value: _trackInventory,
                          onChanged: (value) {
                            setState(() {
                              _trackInventory = value;
                            });
                          },
                        ),

                        const SizedBox(height: AppDims.s3),

                        ProductInventoryAlertsSection(
                          minStockCtrl: _minStockCtrl,
                          expiryAlertCtrl: _expiryAlertCtrl,
                          minStockFocus: _minStockFocus,
                          expiryAlertFocus: _expiryAlertFocus,
                          enabled: _trackInventory,
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
                                    borderRadius:
                                    BorderRadius.circular(AppDims.rMd),
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
                                  'Save Changes',
                                  style: AppTextStyles.bs600(context)
                                      .copyWith(
                                    fontWeight: FontWeight.w900,
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

class _EditCategoryPicker extends StatelessWidget {
  final List<CategoryData> categories;
  final CategoryData? selected;
  final String? fallbackSelectedId;
  final String? fallbackSelectedName;
  final ValueChanged<CategoryData> onSelected;

  const _EditCategoryPicker({
    required this.categories,
    required this.selected,
    required this.fallbackSelectedId,
    required this.fallbackSelectedName,
    required this.onSelected,
  });

  String? get _selectedName {
    final selectedName = selected?.name;
    if (selectedName != null && selectedName.trim().isNotEmpty) {
      return selectedName;
    }

    if (fallbackSelectedName != null &&
        fallbackSelectedName!.trim().isNotEmpty) {
      return fallbackSelectedName;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = _selectedName;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: context.appColors.textHint,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              selectedName ?? 'Category locked',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w700,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          Text(
            'Locked',
            style: AppTextStyles.bs100(context).copyWith(
              color: context.appColors.textHint,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditUnitPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _EditUnitPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDims.s2,
      runSpacing: AppDims.s2,
      children: _kProductUnits.map((unit) {
        final isSelected = unit == selected;

        return GestureDetector(
          onTap: () => onSelected(unit),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s3,
              vertical: AppDims.s2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.appColors.primary.withValues(alpha: 0.10)
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

class _EditTrackInventoryToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EditTrackInventoryToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s3,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 18,
            color: context.appColors.textHint,
          ),
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