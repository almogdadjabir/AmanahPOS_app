
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/image_upload_box.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_inventory_alerts_section.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/features/products/presentation/widgets/track_inventory_toggle.dart';
import 'package:amana_pos/features/products/presentation/widgets/unit_picker.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:amana_pos/widgets/optional_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      child: _EditProductSheet(
        product:      product,
        isRestaurant: context.read<AuthBloc>().state.permissions.isRestaurant,
      ),
    ),
  );
}

class _EditProductSheet extends StatefulWidget {
  final ProductData product;
  final bool isRestaurant;
  const _EditProductSheet({required this.product, required this.isRestaurant});

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
  late final TextEditingController _expiryCtrl;

  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _costFocus = FocusNode();
  final _descFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _barcodeFocus = FocusNode();
  final _minStockFocus = FocusNode();
  final _expiryFocus = FocusNode();

  late String _selectedUnit;
  late bool _trackInventory;
  PickedAppImage? _pickedImage;
  late final List<String> _units;

  String? get _categoryId =>
      widget.product.category?.trim().isNotEmpty == true
          ? widget.product.category : null;

  String? get _categoryName =>
      widget.product.categoryName?.trim().isNotEmpty == true
          ? widget.product.categoryName : null;

  @override
  void initState() {
    super.initState();
    _units = widget.isRestaurant ? kUnitsRestaurant : kUnitsShop;
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.name ?? '');
    _priceCtrl = TextEditingController(text: p.price?.toString() ?? '');
    _costCtrl = TextEditingController(text: p.costPrice?.toString() ?? '');
    _descCtrl = TextEditingController(text: p.description ?? '');
    _skuCtrl = TextEditingController(text: p.sku ?? '');
    _barcodeCtrl = TextEditingController(text: p.barcode ?? '');
    _minStockCtrl = TextEditingController(text: p.minStockLevel?.toString() ?? '');
    _expiryCtrl = TextEditingController();
    final saved = p.unit?.trim() ?? '';
    _selectedUnit = _units.contains(saved) ? saved : _units.first;
    _trackInventory = p.trackInventory ?? true;
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
    final productId = widget.product.id;
    if (productId == null) {
      GlobalSnackBar.show(message: 'Invalid product', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      GlobalSnackBar.show(message: 'Category is missing', isError: true);
      return;
    }
    context.read<ProductBloc>().add(OnUpdateProduct(
      productId: productId,
      dto: UpdateProductRequestDto(
        name: _nameCtrl.text.trim(),
        price: _priceCtrl.text.trim(),
        costPrice: _costCtrl.text.trim().isEmpty ? null : _costCtrl.text.trim(),
        category: _categoryId!,
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
          GlobalSnackBar.show(message: 'Product updated successfully', isInfo: true);
        }
        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true, isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: 'Edit Product',
        maxHeightFactor: 0.90,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ImageUploadBox(
                pickedImage: _pickedImage, imageUrl: widget.product.image,
                title: 'Product photo', subtitle: 'Tap to change product image',
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

              // Category — locked in edit mode
              FieldLabel(label: 'Category', required: true),
              const SizedBox(height: AppDims.s1),
              _LockedCategoryField(name: _categoryName),
              const SizedBox(height: AppDims.s3),

              if (!widget.isRestaurant) ...[
                FieldLabel(label: 'Unit', required: true),
                const SizedBox(height: AppDims.s2),
                UnitPicker(
                  units: _units, selected: _selectedUnit,
                  onSelected: (u) => setState(() => _selectedUnit = u),
                ),
                const SizedBox(height: AppDims.s4),
              ] else
                const SizedBox(height: AppDims.s1),

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
              ProductSubmitButton(label: 'Save Changes', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}


class _LockedCategoryField extends StatelessWidget {
  final String? name;
  const _LockedCategoryField({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height:  52,
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
      decoration: BoxDecoration(
        color:        colors.surfaceSoft.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border:       Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: colors.textHint),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              name ?? 'Category locked',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w700,
                color:      colors.textSecondary,
              ),
            ),
          ),
          Text(
            'Locked',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint, fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}