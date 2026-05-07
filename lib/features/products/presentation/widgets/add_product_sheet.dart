import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/image_upload_box.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/category_picker.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_inventory_alerts_section.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/features/products/presentation/widgets/track_inventory_toggle.dart';
import 'package:amana_pos/features/products/presentation/widgets/unit_picker.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:amana_pos/widgets/optional_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showAddProductSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ProductBloc>(),
      child: _AddProductSheet(
        isRestaurant: context.read<AuthBloc>().state.permissions.isRestaurant,
      ),
    ),
  );
}

class _AddProductSheet extends StatefulWidget {
  final bool isRestaurant;
  const _AddProductSheet({required this.isRestaurant});

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
  final _barcodeCtrl  = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _costFocus = FocusNode();
  final _descFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _barcodeFocus = FocusNode();
  final _minStockFocus = FocusNode();
  final _expiryFocus = FocusNode();

  CategoryData? _selectedCategory;
  String _selectedUnit = 'pcs';
  bool _trackInventory = true;
  PickedAppImage? _pickedImage;

  late final List<String> _units;

  @override
  void initState() {
    super.initState();
    _units = widget.isRestaurant ? kUnitsRestaurant : kUnitsShop;
    final cats = context.read<ProductBloc>().state.categories;
    if (cats.isNotEmpty) _selectedCategory = cats.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _costCtrl.dispose();
    _descCtrl.dispose(); _skuCtrl.dispose(); _barcodeCtrl.dispose();
    _minStockCtrl.dispose(); _expiryCtrl.dispose();
    _nameFocus.dispose(); _priceFocus.dispose(); _costFocus.dispose();
    _descFocus.dispose(); _skuFocus.dispose(); _barcodeFocus.dispose();
    _minStockFocus.dispose(); _expiryFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      GlobalSnackBar.show(message: 'Please select a category', isError: true);
      return;
    }
    context.read<ProductBloc>().add(OnAddProduct(
      dto: AddProductRequestDto(
        name: _nameCtrl.text.trim(),
        price: _priceCtrl.text.trim(),
        costPrice: _costCtrl.text.trim().isEmpty ? null : _costCtrl.text.trim(),
        category: _selectedCategory!.id!,
        unit: _selectedUnit,
        trackInventory: !widget.isRestaurant && _trackInventory,
        minStockLevel: (!widget.isRestaurant && _minStockCtrl.text.trim().isNotEmpty)
            ? _minStockCtrl.text.trim() : null,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        imageUpload: _pickedImage,
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
          GlobalSnackBar.show(message: 'Product added successfully', isInfo: true);
        }
        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true, isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: 'New Product',
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ImageUploadBox(
                pickedImage: _pickedImage, imageUrl: null,
                title: 'Add product photo',
                subtitle: 'Use a clear image for faster cashier selection',
                onChanged: (img) => setState(() => _pickedImage = img),
              ),
              const SizedBox(height: AppDims.s3),

              FieldLabel(label: 'Product Name', required: true),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl, focusNode: _nameFocus,
                nextFocus: _priceFocus, hint: 'Pepsi 330ml',
                prefixIcon: Icons.inventory_2_outlined,
                validator: ProductFormValidators.name,
              ),
              const SizedBox(height: AppDims.s3),

              ProductPriceRow(
                priceCtrl: _priceCtrl, costCtrl: _costCtrl,
                priceFocus: _priceFocus, costFocus: _costFocus,
                nextFocus: _descFocus,
              ),
              const SizedBox(height: AppDims.s3),

              FieldLabel(label: 'Category', required: true),
              const SizedBox(height: AppDims.s1),
              BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (prev, curr) => prev.categories != curr.categories,
                builder: (context, state) => CategoryPicker(
                  categories: state.categories,
                  selected: _selectedCategory,
                  onSelected: (c) => setState(() => _selectedCategory = c),
                ),
              ),
              const SizedBox(height: AppDims.s3),

              if (!widget.isRestaurant) ...[
                FieldLabel(label: 'Unit', required: true),
                const SizedBox(height: AppDims.s2),
                UnitPicker(
                  units: _units, selected: _selectedUnit,
                  onSelected: (u) => setState(() => _selectedUnit = u),
                ),
              ],

              const SizedBox(height: AppDims.s4),
              OptionalDivider(),
              const SizedBox(height: AppDims.s4),

              FieldLabel(label: 'Description'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _descCtrl, focusNode: _descFocus,
                nextFocus: _skuFocus, hint: 'Product description',
                prefixIcon: Icons.notes_rounded, maxLines: 3,
              ),
              const SizedBox(height: AppDims.s3),

              if (!widget.isRestaurant) ...[
                ProductSkuBarcodeRow(
                  skuCtrl: _skuCtrl, barcodeCtrl: _barcodeCtrl,
                  skuFocus: _skuFocus, barcodeFocus: _barcodeFocus,
                ),
                const SizedBox(height: AppDims.s3),
                TrackInventoryToggle(
                  value: _trackInventory,
                  onChanged: (v) => setState(() => _trackInventory = v),
                ),
                const SizedBox(height: AppDims.s3),
                ProductInventoryAlertsSection(
                  minStockCtrl: _minStockCtrl, expiryAlertCtrl: _expiryCtrl,
                  minStockFocus: _minStockFocus, expiryAlertFocus: _expiryFocus,
                  enabled: _trackInventory,
                ),
              ],

              const SizedBox(height: AppDims.s5),
              ProductSubmitButton(label: 'Add Product', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}