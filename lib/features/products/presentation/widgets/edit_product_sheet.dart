import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/image_upload_box.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_barcode_field.dart';
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
import 'package:solar_icons/solar_icons.dart';

void showEditProductSheet(
    BuildContext context, {
      required ProductData product,
    }) {
  final productBloc = context.read<ProductBloc>();
  final isRestaurant = context.read<AuthBloc>().state.permissions.isRestaurant;

  showAdaptivePanel(
    context,
    desktopWidth: 480,
    builder: (_) => BlocProvider.value(
      value: productBloc,
      child: _EditProductSheet(
        product: product,
        isRestaurant: isRestaurant,
      ),
    ),
  );
}

class _EditProductSheet extends StatefulWidget {
  final ProductData product;
  final bool isRestaurant;

  const _EditProductSheet({
    required this.product,
    required this.isRestaurant,
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
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _expiryCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _priceFocus;
  late final FocusNode _costFocus;
  late final FocusNode _descFocus;
  late final FocusNode _barcodeFocus;
  late final FocusNode _minStockFocus;
  late final FocusNode _expiryFocus;

  late final String _categoryId;
  late final String? _categoryName;
  late final List<String> _units;
  late String _selectedUnit;
  late bool _trackInventory;

  PickedAppImage? _pickedImage;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _units = widget.isRestaurant ? kUnitsRestaurant : kUnitsShop;

    _categoryId = product.category?.trim() ?? '';
    _categoryName = product.categoryName?.trim().isNotEmpty == true
        ? product.categoryName!.trim()
        : null;

    _nameCtrl = TextEditingController(text: product.name ?? '');
    _priceCtrl = TextEditingController(text: product.price?.toString() ?? '');
    _costCtrl = TextEditingController(text: product.costPrice?.toString() ?? '');
    _descCtrl = TextEditingController(text: product.description ?? '');
    _barcodeCtrl = TextEditingController(text: product.barcode ?? '');
    _minStockCtrl = TextEditingController(
      text: product.minStockLevel?.toString() ?? '',
    );
    _expiryCtrl = TextEditingController(
      text: product.expiryAlertDays?.toString() ?? '',
    );

    _nameFocus = FocusNode();
    _priceFocus = FocusNode();
    _costFocus = FocusNode();
    _descFocus = FocusNode();
    _barcodeFocus = FocusNode();
    _minStockFocus = FocusNode();
    _expiryFocus = FocusNode();

    final savedUnit = product.unit?.trim() ?? '';
    _selectedUnit = _units.contains(savedUnit) ? savedUnit : _units.first;
    _trackInventory = product.trackInventory ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _descCtrl.dispose();
    _barcodeCtrl.dispose();
    _minStockCtrl.dispose();
    _expiryCtrl.dispose();

    _nameFocus.dispose();
    _priceFocus.dispose();
    _costFocus.dispose();
    _descFocus.dispose();
    _barcodeFocus.dispose();
    _minStockFocus.dispose();
    _expiryFocus.dispose();

    super.dispose();
  }

  void _submit() {
    final tr = context.tr;
    final productId = widget.product.id;

    if (productId == null || productId.isEmpty) {
      GlobalSnackBar.show(
        message: tr.invalidProduct,
        isError: true,
      );
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (_categoryId.isEmpty) {
      GlobalSnackBar.show(
        message: tr.categoryMissing,
        isError: true,
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final price = _priceCtrl.text.trim();
    final costPrice = _costCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim();
    final minStock = _minStockCtrl.text.trim();
    final expiryDays = _expiryCtrl.text.trim();

    final shouldTrackInventory = !widget.isRestaurant && _trackInventory;

    context.read<ProductBloc>().add(
      OnUpdateProduct(
        productId: productId,
        dto: UpdateProductRequestDto(
          name: name,
          price: price,
          costPrice: costPrice.isEmpty ? null : costPrice,
          category: _categoryId,
          unit: _selectedUnit,
          trackInventory: shouldTrackInventory,
          minStockLevel:
          shouldTrackInventory && minStock.isNotEmpty ? minStock : null,
          description: description.isEmpty ? null : description,
          barcode: barcode.isEmpty ? null : barcode,
          expiryAlertDays: shouldTrackInventory && expiryDays.isNotEmpty
              ? expiryDays
              : null,
          imageUpload: _pickedImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: context.tr.productUpdatedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: tr.editProduct,
        maxHeightFactor: 0.90,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageUploadBox(
                pickedImage: _pickedImage,
                imageUrl: widget.product.image,
                title: tr.productPhoto,
                subtitle: tr.tapToChangeProductImage,
                onChanged: (image) {
                  setState(() => _pickedImage = image);
                },
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(
                label: tr.fieldProductName,
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                nextFocus: _priceFocus,
                hint: tr.productNameHint,
                prefixIcon: SolarIconsOutline.box,
                validator: (value) {
                  return ProductFormValidators.name(context, value);
                },
              ),

              const SizedBox(height: AppDims.s3),

              ProductPriceRow(
                priceCtrl: _priceCtrl,
                costCtrl: _costCtrl,
                priceFocus: _priceFocus,
                costFocus: _costFocus,
                nextFocus: _descFocus,
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(
                label: tr.fieldCategory,
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              _LockedCategoryField(name: _categoryName),

              const SizedBox(height: AppDims.s3),

              if (!widget.isRestaurant) ...[
                FieldLabel(
                  label: tr.fieldUnit,
                  required: true,
                ),
                const SizedBox(height: AppDims.s2),
                UnitPicker(
                  units: _units,
                  selected: _selectedUnit,
                  onSelected: (unit) {
                    setState(() => _selectedUnit = unit);
                  },
                ),
                const SizedBox(height: AppDims.s4),
              ] else
                const SizedBox(height: AppDims.s1),

              const OptionalDivider(),
              const SizedBox(height: AppDims.s4),

              FieldLabel(label: tr.fieldDescription),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                nextFocus: _barcodeFocus,
                hint: tr.productDescriptionHint,
                prefixIcon: SolarIconsOutline.notes,
                maxLines: 3,
              ),

              const SizedBox(height: AppDims.s3),

              if (!widget.isRestaurant) ...[
                ProductBarcodeField(
                  controller: _barcodeCtrl,
                  focusNode: _barcodeFocus,
                ),

                const SizedBox(height: AppDims.s3),

                TrackInventoryToggle(
                  value: _trackInventory,
                  onChanged: (value) {
                    setState(() => _trackInventory = value);
                  },
                ),

                const SizedBox(height: AppDims.s3),

                ProductInventoryAlertsSection(
                  minStockCtrl: _minStockCtrl,
                  expiryAlertCtrl: _expiryCtrl,
                  minStockFocus: _minStockFocus,
                  expiryAlertFocus: _expiryFocus,
                  enabled: _trackInventory,
                ),
              ],

              const SizedBox(height: AppDims.s5),

              ProductSubmitButton(
                label: tr.saveChanges,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedCategoryField extends StatelessWidget {
  final String? name;

  const _LockedCategoryField({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final categoryName = name?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s3,
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.lockKeyhole,
                size: 18,
                color: colors.textHint,
              ),

              const SizedBox(width: AppDims.s2),

              Expanded(
                child: Text(
                  categoryName?.isNotEmpty == true
                      ? categoryName!
                      : context.tr.categoryLocked,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs500(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(width: AppDims.s2),

              Text(
                context.tr.locked,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}