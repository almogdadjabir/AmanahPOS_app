import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/image_upload_box.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/category_picker.dart';
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

void showAddProductSheet(
    BuildContext context, {
      CategoryData? initialCategory,
    }) {
  final productBloc = context.read<ProductBloc>();
  final isRestaurant = context.read<AuthBloc>().state.permissions.isRestaurant;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: productBloc,
      child: _AddProductSheet(
        isRestaurant: isRestaurant,
        initialCategory: initialCategory,
      ),
    ),
  );
}

class _AddProductSheet extends StatefulWidget {
  final bool isRestaurant;
  final CategoryData? initialCategory;

  const _AddProductSheet({
    required this.isRestaurant,
    this.initialCategory,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _expiryCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _priceFocus;
  late final FocusNode _costFocus;
  late final FocusNode _descFocus;
  late final FocusNode _skuFocus;
  late final FocusNode _barcodeFocus;
  late final FocusNode _minStockFocus;
  late final FocusNode _expiryFocus;

  late final List<String> _units;

  CategoryData? _selectedCategory;
  String _selectedUnit = 'pcs';
  bool _trackInventory = true;
  PickedAppImage? _pickedImage;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _costCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _skuCtrl = TextEditingController();
    _barcodeCtrl = TextEditingController();
    _minStockCtrl = TextEditingController();
    _expiryCtrl = TextEditingController();

    _nameFocus = FocusNode();
    _priceFocus = FocusNode();
    _costFocus = FocusNode();
    _descFocus = FocusNode();
    _skuFocus = FocusNode();
    _barcodeFocus = FocusNode();
    _minStockFocus = FocusNode();
    _expiryFocus = FocusNode();

    _units = widget.isRestaurant ? kUnitsRestaurant : kUnitsShop;

    final categories = context.read<ProductBloc>().state.categories;
    final initialCategory = widget.initialCategory;

    if (initialCategory != null) {
      _selectedCategory = _findCategoryById(
        categories,
        initialCategory.id,
      ) ?? initialCategory;
      return;
    }

    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _descCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _minStockCtrl.dispose();
    _expiryCtrl.dispose();

    _nameFocus.dispose();
    _priceFocus.dispose();
    _costFocus.dispose();
    _descFocus.dispose();
    _skuFocus.dispose();
    _barcodeFocus.dispose();
    _minStockFocus.dispose();
    _expiryFocus.dispose();

    super.dispose();
  }

  CategoryData? _findCategoryById(
      List<CategoryData> categories,
      String? categoryId,
      ) {
    if (categoryId == null || categoryId.isEmpty) return null;

    for (final category in categories) {
      if (category.id == categoryId) return category;
    }

    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final name = _nameCtrl.text.trim();
    final price = _priceCtrl.text.trim();
    final cost = _costCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final sku = _skuCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim();
    final minStock = _minStockCtrl.text.trim();
    final expiryDays = _expiryCtrl.text.trim();

    final shouldTrackInventory = !widget.isRestaurant && _trackInventory;

    final dto = AddProductRequestDto(
      name: name,
      price: price,
      costPrice: cost.isEmpty ? null : cost,
      category: _selectedCategory?.id ?? '',
      unit: _selectedUnit,
      trackInventory: shouldTrackInventory,
      minStockLevel: shouldTrackInventory && minStock.isNotEmpty
          ? minStock
          : null,
      description: description.isEmpty ? null : description,
      sku: sku.isEmpty ? null : sku,
      barcode: barcode.isEmpty ? null : barcode,
      expiryAlertDays: shouldTrackInventory && expiryDays.isNotEmpty
          ? expiryDays
          : null,
      imageUpload: _pickedImage,
    );

    final bloc = context.read<ProductBloc>();

    if (_selectedCategory == null) {
      bloc.add(OnAddProductWithAutoCategory(dto: dto));
      return;
    }

    bloc.add(OnAddProduct(dto: dto));
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
            message: context.tr.productAddedSuccessfully,
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
        title: tr.newProduct,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageUploadBox(
                pickedImage: _pickedImage,
                imageUrl: null,
                title: tr.addProductPhoto,
                subtitle: tr.productPhotoSubtitle,
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
                validator: (value) => ProductFormValidators.name(context, value),
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

              BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (prev, curr) => prev.categories != curr.categories,
                builder: (context, state) {
                  final categories = state.categories;
                  final hasCategories = categories.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(
                        label: tr.category,
                        required: hasCategories,
                      ),
                      const SizedBox(height: AppDims.s1),
                      if (hasCategories)
                        CategoryPicker(
                          categories: categories,
                          selected: _selectedCategory,
                          onSelected: (category) {
                            setState(() => _selectedCategory = category);
                          },
                        )
                      else
                        const _AutoCategoryInfo(),
                    ],
                  );
                },
              ),

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
              ],

              const SizedBox(height: AppDims.s4),
              const OptionalDivider(),
              const SizedBox(height: AppDims.s4),

              FieldLabel(label: tr.fieldDescription),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                nextFocus: _skuFocus,
                hint: tr.productDescriptionHint,
                prefixIcon: SolarIconsOutline.notes,
                maxLines: 3,
              ),

              const SizedBox(height: AppDims.s3),

              if (!widget.isRestaurant) ...[
                FieldLabel(label: tr.fieldSku),
                const SizedBox(height: AppDims.s1),
                AppFormField(
                  controller: _skuCtrl,
                  focusNode: _skuFocus,
                  nextFocus: _barcodeFocus,
                  hint: 'SKU-001',
                  prefixIcon: SolarIconsOutline.qrCode,
                ),

                const SizedBox(height: AppDims.s3),

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
                label: tr.addProduct,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoCategoryInfo extends StatelessWidget {
  const _AutoCategoryInfo();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.22),
        ),
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
                SolarIconsOutline.magicStick_3,
                size: 18,
                color: colors.primary,
              ),

              const SizedBox(width: AppDims.s2),

              Expanded(
                child: Text(
                  tr.generalCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),

              const SizedBox(width: AppDims.s2),

              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s2,
                    vertical: 3,
                  ),
                  child: Text(
                    tr.autoCreated,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sm200(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
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