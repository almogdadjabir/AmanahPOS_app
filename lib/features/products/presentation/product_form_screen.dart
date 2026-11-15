import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/image_upload_box.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/update_stock_screen.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/features/products/presentation/widgets/category_picker_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/option_picker_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_form_widgets.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the new / edit product screen.
/// [product] null = new product. [initialCategory] preselects a category.
Future<void> openProductForm(
  BuildContext context, {
  ProductData? product,
  CategoryData? initialCategory,
}) {
  final productBloc = context.read<ProductBloc>();

  // Callers differ: only the detail route carries an InventoryBloc.
  InventoryBloc? inventoryBloc;
  try {
    inventoryBloc = context.read<InventoryBloc>();
  } catch (_) {
    inventoryBloc = null;
  }

  final form = _ProductFormScreen(
    product: product,
    initialCategory: initialCategory,
  );

  return Navigator.of(context).push(
    motionPageRoute(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productBloc),
          if (inventoryBloc != null) BlocProvider.value(value: inventoryBloc),
        ],
        child: form,
      ),
    ),
  );
}

class _ProductFormScreen extends StatefulWidget {
  final ProductData? product;
  final CategoryData? initialCategory;

  const _ProductFormScreen({this.product, this.initialCategory});

  @override
  State<_ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<_ProductFormScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _startStockCtrl = TextEditingController();

  late final bool _isRestaurant;
  late final bool _isCashier;
  late final List<String> _units;

  CategoryData? _category;
  String _unit = 'pcs';
  bool _track = true;
  bool _expanded = false;
  bool _deleting = false;
  PickedAppImage? _image;

  List<ShopData> _shops = const [];
  ShopData? _shop;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final permissions = context.read<AuthBloc>().state.permissions;
    _isRestaurant = permissions.isRestaurant;
    _isCashier = permissions.isCashier;
    _units = _isRestaurant ? kUnitsRestaurant : kUnitsShop;

    final businesses = context.read<BusinessBloc>().state.businessList;
    _shops = businesses == null || businesses.isEmpty
        ? const []
        : (businesses.first.shops ?? const [])
              .where((s) => s.id?.trim().isNotEmpty ?? false)
              .toList(growable: false);
    _shop = _shops.isEmpty ? null : _shops.first;

    final product = widget.product;
    if (product != null) {
      _nameCtrl.text = product.name ?? '';
      _priceCtrl.text = product.price ?? '';
      _costCtrl.text = product.costPrice ?? '';
      _descCtrl.text = product.description ?? '';
      _skuCtrl.text = product.sku ?? '';
      _barcodeCtrl.text = product.barcode ?? '';
      _minStockCtrl.text = product.minStockLevel == null
          ? ''
          : formatQty(product.minStockLevel!);
      _expiryCtrl.text = product.expiryAlertDays?.toString() ?? '';
      final saved = product.unit?.trim() ?? '';
      _unit = _units.contains(saved) ? saved : _units.first;
      _track = product.trackInventory ?? true;
      _expanded = true;
    } else {
      _unit = _units.first;
    }

    for (final c in [_nameCtrl, _priceCtrl]) {
      c.addListener(_refresh);
    }
  }

  bool _categoryResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs localizations (the General lookup), so it cannot run in initState.
    if (_categoryResolved || widget.product != null) return;
    _categoryResolved = true;
    _category = _resolveInitialCategory();
  }

  CategoryData? _resolveInitialCategory() {
    final categories = context.read<ProductBloc>().state.categories;
    final initial = widget.initialCategory;
    if (initial != null) {
      for (final c in categories) {
        if (c.id == initial.id) return c;
      }
      return initial;
    }
    return _existingGeneral(categories);
  }

  CategoryData? _existingGeneral(List<CategoryData> categories) {
    final general = context.tr.generalCategory.trim().toLowerCase();
    for (final c in categories) {
      final name = c.name?.trim().toLowerCase();
      if (name == 'general' || name == general) return c;
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _priceCtrl,
      _costCtrl,
      _descCtrl,
      _skuCtrl,
      _barcodeCtrl,
      _minStockCtrl,
      _expiryCtrl,
      _startStockCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _valid =>
      ProductFormValidators.name(context, _nameCtrl.text) == null &&
      ProductFormValidators.price(context, _priceCtrl.text) == null;

  bool get _tracking => !_isRestaurant && _track;

  // ---------------------------------------------------------------- actions

  Future<void> _pickCategory() async {
    final choice = await showProductCategoryPicker(
      context,
      bloc: context.read<ProductBloc>(),
      selectedId: _category?.id,
    );
    if (choice == null || !mounted) return;
    setState(() => _category = choice.category);
  }

  Future<void> _pickUnit() async {
    final picked = await showOptionPicker<String>(
      context,
      title: context.tr.pfUnit,
      options: [for (final u in _units) PickerOption(value: u, label: u)],
      selected: _unit,
    );
    if (picked == null || !mounted) return;
    setState(() => _unit = picked);
  }

  Future<void> _pickShop() async {
    final picked = await showOptionPicker<String>(
      context,
      title: context.tr.shop,
      options: [
        for (final s in _shops)
          PickerOption(
            value: s.id!,
            label: s.name?.trim().isNotEmpty == true ? s.name!.trim() : s.id!,
          ),
      ],
      selected: _shop?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _shop = _shops.firstWhere((s) => s.id == picked));
  }

  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).pushNamed<String>(RouteStrings.barcodeScannerScreen);
    final clean = code?.trim();
    if (!mounted || clean == null || clean.isEmpty) return;
    setState(() => _barcodeCtrl.text = clean);
  }

  /// Returns a message when an optional numeric field is invalid.
  String? _extraError() {
    final tr = context.tr;

    if (!_isCashier) {
      final cost = ProductFormValidators.optionalPrice(context, _costCtrl.text);
      if (cost != null) return cost;
    }

    double? parse(String t) => double.tryParse(t.trim());

    final start = _startStockCtrl.text.trim();
    if (!_isEdit && _tracking && start.isNotEmpty) {
      final v = parse(start);
      if (v == null || v < 0) return tr.fbInvalidNumber;
    }

    final min = _minStockCtrl.text.trim();
    if (_tracking && min.isNotEmpty) {
      final v = parse(min);
      if (v == null || v < 0) return tr.fbInvalidNumber;
    }

    final days = _expiryCtrl.text.trim();
    if (_tracking && days.isNotEmpty) {
      final v = int.tryParse(days);
      if (v == null || v <= 0) return tr.fbInvalidDays;
    }
    return null;
  }

  void _submit() {
    if (!_valid) return;
    final tr = context.tr;

    final error = _extraError();
    if (error != null) {
      setState(() => _expanded = true);
      GlobalSnackBar.show(message: error, isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    final name = _nameCtrl.text.trim();
    final price = _priceCtrl.text.trim();
    final cost = _isCashier ? '' : _costCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final sku = _skuCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim();
    final minStock = _minStockCtrl.text.trim();
    final expiryDays = _expiryCtrl.text.trim();
    final tracking = _tracking;
    final bloc = context.read<ProductBloc>();

    final existing = widget.product;
    if (existing != null) {
      final productId = existing.id;
      if (productId == null || productId.isEmpty) {
        GlobalSnackBar.show(message: tr.invalidProduct, isError: true);
        return;
      }
      final categoryId = existing.category?.trim() ?? '';
      if (categoryId.isEmpty) {
        GlobalSnackBar.show(message: tr.categoryMissing, isError: true);
        return;
      }

      bloc.add(
        OnUpdateProduct(
          productId: productId,
          dto: UpdateProductRequestDto(
            name: name,
            price: price,
            costPrice: cost.isEmpty ? null : cost,
            category: categoryId,
            unit: _unit,
            trackInventory: tracking,
            minStockLevel: tracking && minStock.isNotEmpty ? minStock : null,
            description: description.isEmpty ? null : description,
            barcode: barcode.isEmpty ? null : barcode,
            expiryAlertDays: tracking && expiryDays.isNotEmpty
                ? expiryDays
                : null,
            imageUpload: _image,
          ),
        ),
      );
      return;
    }

    final dto = AddProductRequestDto(
      name: name,
      price: price,
      costPrice: cost.isEmpty ? null : cost,
      category: _category?.id ?? '',
      unit: _unit,
      trackInventory: tracking,
      minStockLevel: tracking && minStock.isNotEmpty ? minStock : null,
      description: description.isEmpty ? null : description,
      sku: sku.isEmpty ? null : sku,
      barcode: barcode.isEmpty ? null : barcode,
      expiryAlertDays: tracking && expiryDays.isNotEmpty ? expiryDays : null,
      imageUpload: _image,
    );

    final startRaw = _startStockCtrl.text.trim();
    final hasOpening =
        tracking &&
        startRaw.isNotEmpty &&
        (double.tryParse(startRaw) ?? 0) > 0 &&
        _shop != null;
    final openingStock = hasOpening ? startRaw : null;
    final openingShopId = hasOpening ? _shop!.id : null;

    if (_category == null) {
      bloc.add(
        OnAddProductWithAutoCategory(
          dto: dto,
          openingStock: openingStock,
          openingShopId: openingShopId,
        ),
      );
      return;
    }

    bloc.add(
      OnAddProduct(
        dto: dto,
        openingStock: openingStock,
        openingShopId: openingShopId,
      ),
    );
  }

  Future<void> _delete() async {
    final product = widget.product;
    final productId = product?.id;
    final tr = context.tr;

    if (product == null || productId == null || productId.isEmpty) {
      GlobalSnackBar.show(message: tr.invalidProduct, isError: true);
      return;
    }

    final confirmed = await showAppConfirmSheet(
      context,
      title: tr.pcDeleteTitle(productDisplayName(context, product)),
      message: tr.pcDeleteBody,
      confirmLabel: tr.delete,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    context.read<ProductBloc>().add(OnDeleteProduct(productId: productId));
  }

  void _onSubmitState(BuildContext context, ProductState state) {
    final tr = context.tr;

    if (state.submitStatus == ProductSubmitStatus.success) {
      final navigator = Navigator.of(context);

      if (_deleting) {
        navigator.pop();
        navigator.maybePop();
        GlobalSnackBar.show(message: tr.pcDeleted, isInfo: true);
        return;
      }

      navigator.pop();
      final warning = state.submitWarning;
      if (!_isEdit && warning != null && warning.trim().isNotEmpty) {
        GlobalSnackBar.showWarning(
          message: tr.fbOpeningStockWarning,
          isAutoDismiss: false,
        );
      } else {
        GlobalSnackBar.show(
          message: _isEdit
              ? tr.productUpdatedSuccessfully
              : tr.productAddedSuccessfully,
          isInfo: true,
        );
      }
      return;
    }

    if (state.submitStatus == ProductSubmitStatus.failure) {
      if (_deleting) setState(() => _deleting = false);
      GlobalSnackBar.show(
        message: state.submitError ?? tr.somethingWentWrong,
        isError: true,
        isAutoDismiss: false,
      );
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final currency = context.select<DashboardSummaryBloc, String>(
      (b) => b.state.summary?.currency ?? 'SDG',
    );
    final saving = context.select<ProductBloc, bool>(
      (b) => b.state.submitStatus == ProductSubmitStatus.loading,
    );

    final existing = widget.product;
    final showStockGroup = !_isRestaurant;
    final showAlerts = !_isRestaurant && (_isEdit ? true : _track);

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: _onSubmitState,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              FormNavBar(
                title: _isEdit ? tr.pfEditProduct : tr.pfNewProduct,
                onCancel: () => Navigator.of(context).maybePop(),
                onSave: _valid ? _submit : null,
                saving: saving,
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s2,
                    AppDims.s4,
                    AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormPhotoTile(
                        picked: _image,
                        imageUrl: existing?.detailImageUrl,
                        onTap: () => ImageUploadBox.showPicker(
                          context,
                          (image) => setState(() => _image = image),
                        ),
                      ),
                      const SizedBox(height: AppDims.s4),
                      _identityGroup(currency),
                      if (showStockGroup) ...[
                        const SizedBox(height: AppDims.s4),
                        _stockGroup(),
                      ],
                      const SizedBox(height: AppDims.s4),
                      _detailsGroup(currency, showAlerts),
                      if (_isEdit) ...[
                        const SizedBox(height: AppDims.s6),
                        AppFormGroup(
                          children: [
                            AppFormRow(
                              onTap: saving ? null : _delete,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.trash,
                                    size: 20,
                                    color: colors.danger,
                                  ),
                                  const SizedBox(width: AppDims.s2),
                                  Text(
                                    tr.pfDeleteProduct,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: colors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityGroup(String currency) {
    final tr = context.tr;
    final colors = context.appColors;
    final categoryName = _isEdit
        ? (widget.product!.categoryName?.trim().isNotEmpty == true
              ? widget.product!.categoryName!.trim()
              : tr.categoryLocked)
        : (_category?.name?.trim().isNotEmpty == true
              ? _category!.name!.trim()
              : tr.generalCategory);

    return AppFormGroup(
      footer: _isEdit ? tr.pfCategoryLockedNote : null,
      children: [
        AppFormRow(
          label: tr.pfName,
          child: AppRowTextField(
            controller: _nameCtrl,
            hint: tr.productNameHint,
          ),
        ),
        AppFormRow(
          label: tr.fieldPrice,
          child: AppRowTextField(
            controller: _priceCtrl,
            hint: '0',
            numeric: true,
            suffix: currency,
          ),
        ),
        if (_isEdit)
          AppFormRow(
            label: tr.category,
            child: AppRowValue(
              categoryName,
              leading: Icon(
                PhosphorIconsRegular.lock,
                size: 16,
                color: colors.textHint,
              ),
            ),
          )
        else
          AppFormRow(
            label: tr.category,
            onTap: _pickCategory,
            chevron: true,
            child: AppRowValue(categoryName),
          ),
      ],
    );
  }

  Widget _stockGroup() {
    final tr = context.tr;

    if (_isEdit) {
      final product = widget.product!;
      if (product.trackInventory == false) return const SizedBox.shrink();

      final qty = context.select<ProductBloc, double>((b) {
        for (final p in b.state.products) {
          if (p.id == product.id) return p.stockLevel ?? 0;
        }
        return product.stockLevel ?? 0;
      });

      return AppFormGroup(
        children: [
          AppFormRow(
            label: tr.stock,
            chevron: true,
            onTap: () => openUpdateStock(context, product: product),
            child: AppRowValue(
              tr.pfStockRowValue(formatQty(qty), _unit),
              numeric: true,
            ),
          ),
        ],
      );
    }

    return AppFormGroup(
      children: [
        AppSwitchRow(
          title: tr.pfTrackStock,
          subtitle: tr.pfTrackStockHint,
          value: _track,
          onChanged: (v) => setState(() => _track = v),
        ),
        if (_track) ...[
          AppFormRow(
            label: tr.pfStartingStock,
            child: AppRowTextField(
              controller: _startStockCtrl,
              hint: '0',
              numeric: true,
            ),
          ),
          if (_shops.length > 1)
            AppFormRow(
              label: tr.shop,
              onTap: _pickShop,
              chevron: true,
              child: AppRowValue(
                _shop?.name?.trim().isNotEmpty == true
                    ? _shop!.name!.trim()
                    : '',
              ),
            ),
        ],
      ],
    );
  }

  Widget _detailsGroup(String currency, bool showAlerts) {
    final tr = context.tr;

    final disclosure = FormDisclosureRow(
      expanded: _expanded,
      onTap: () => setState(() => _expanded = !_expanded),
    );

    if (!_expanded) {
      return AppFormGroup(children: [disclosure]);
    }

    return AppFormGroup(
      children: [
        if (!_isRestaurant)
          AppFormRow(
            label: tr.pfUnit,
            onTap: _pickUnit,
            chevron: true,
            child: AppRowValue(_unit),
          ),
        if (!_isRestaurant)
          AppFormRow(
            label: tr.pfBarcode,
            child: Row(
              children: [
                Expanded(
                  child: AppRowTextField(
                    controller: _barcodeCtrl,
                    hint: tr.optional,
                    numeric: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _scan,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      PhosphorIconsRegular.scan,
                      size: 22,
                      color: context.appColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!_isRestaurant)
          AppFormRow(
            label: tr.fieldSku,
            child: _isEdit
                ? AppRowValue(
                    _skuCtrl.text.isEmpty ? tr.optional : _skuCtrl.text,
                    numeric: true,
                    placeholder: _skuCtrl.text.isEmpty,
                  )
                : AppRowTextField(
                    controller: _skuCtrl,
                    hint: tr.optional,
                    numeric: true,
                    keyboardType: TextInputType.text,
                  ),
          ),
        if (!_isCashier)
          AppFormRow(
            label: tr.pfCostPrice,
            child: AppRowTextField(
              controller: _costCtrl,
              hint: tr.optional,
              numeric: true,
              suffix: currency,
            ),
          ),
        AppFormRow(
          label: tr.fieldDescription,
          align: CrossAxisAlignment.start,
          minHeight: 96,
          child: AppRowTextField(
            controller: _descCtrl,
            hint: tr.productDescriptionHint,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
        ),
        if (showAlerts)
          AppFormRow(
            label: tr.pfLowStockAlert,
            child: AppRowTextField(
              controller: _minStockCtrl,
              hint: tr.optional,
              numeric: true,
            ),
          ),
        if (showAlerts)
          AppFormRow(
            label: tr.pfExpiryAlert,
            child: AppRowTextField(
              controller: _expiryCtrl,
              hint: tr.optional,
              numeric: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
            ),
          ),
        FormDisclosureRow(
          expanded: true,
          onTap: () => setState(() => _expanded = false),
        ),
      ],
    );
  }
}
