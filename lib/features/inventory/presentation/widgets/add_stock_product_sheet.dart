import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/data/models/movement_type.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showAddStockProductSheet(
    BuildContext context, {
      ProductData? initialProduct,
      ShopData? initialShop,
    }) {
  final inventoryBloc = context.read<InventoryBloc>();
  final productBloc = context.read<ProductBloc>();
  final businessBloc = context.read<BusinessBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: inventoryBloc),
        BlocProvider.value(value: productBloc),
        BlocProvider.value(value: businessBloc),
      ],
      child: _AddStockProductSheet(
        initialProduct: initialProduct,
        initialShop: initialShop,
      ),
    ),
  );
}

class _AddStockProductSheet extends StatefulWidget {
  final ProductData? initialProduct;
  final ShopData? initialShop;

  const _AddStockProductSheet({
    this.initialProduct,
    this.initialShop,
  });

  @override
  State<_AddStockProductSheet> createState() => _AddStockProductSheetState();
}

class _AddStockProductSheetState extends State<_AddStockProductSheet> {
  final _formKey = GlobalKey<FormState>();

  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  final _qtyFocus = FocusNode();
  final _refFocus = FocusNode();

  ProductData? _selectedProduct;
  ShopData? _selectedShop;
  MovementType _movementType = MovementType.opening;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();

    _selectedProduct = widget.initialProduct;

    final shops = _shopsFromBusiness(context);
    _selectedShop = widget.initialShop ?? _firstValidShop(shops);

    final productState = context.read<ProductBloc>().state;
    if (_selectedProduct == null && productState.products.isEmpty) {
      context.read<ProductBloc>().add(const OnProductInitial());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _refCtrl.dispose();
    _qtyFocus.dispose();
    _refFocus.dispose();
    super.dispose();
  }

  ShopData? _firstValidShop(List<ShopData> shops) {
    for (final shop in shops) {
      final id = shop.id;
      if (id != null && id.trim().isNotEmpty) return shop;
    }

    return null;
  }

  List<ShopData> _shopsFromBusiness(BuildContext context) {
    final businessState = context.read<BusinessBloc>().state;
    final businesses = businessState.businessList;

    if (businesses == null || businesses.isEmpty) {
      return const [];
    }

    return businesses.first.shops ?? const [];
  }

  void _clearSelectedProduct() {
    setState(() {
      _selectedProduct = null;
      _qtyCtrl.clear();
      _refCtrl.clear();
      _selectedExpiryDate = null;
      _movementType = MovementType.opening;
    });
  }

  void _submit() {
    final productId = _selectedProduct?.id;
    final shopId = _selectedShop?.id;

    if (productId == null || productId.trim().isEmpty) {
      GlobalSnackBar.show(
        message: 'Please select a product',
        isError: true,
      );
      return;
    }

    if (shopId == null || shopId.trim().isEmpty) {
      GlobalSnackBar.show(
        message: 'Please select a shop',
        isError: true,
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    context.read<InventoryBloc>().add(
      OnAddStock(
        productId: productId,
        shopId: shopId,
        quantity: _qtyCtrl.text.trim(),
        movementType: _movementType,
        reference: _refCtrl.text.trim().isEmpty
            ? null
            : _refCtrl.text.trim(),
        expiryDate: _selectedExpiryDate == null
            ? null
            : '${_selectedExpiryDate!.year.toString().padLeft(4, '0')}'
            '-${_selectedExpiryDate!.month.toString().padLeft(2, '0')}'
            '-${_selectedExpiryDate!.day.toString().padLeft(2, '0')}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<InventoryBloc, InventoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == InventorySubmitStatus.success) {
          Navigator.of(context).pop();

          context.read<InventoryBloc>().add(const OnInventoryInitial());

          GlobalSnackBar.show(
            message: 'Stock added successfully',
            isInfo: true,
          );
        }

        if (state.submitStatus == InventorySubmitStatus.failure) {
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
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDims.s3),
              _SheetHandle(color: colors.border),
              _SheetHeader(
                title: 'Add Stock',
                subtitle: _selectedProduct == null
                    ? 'Select a product and assign quantity to a shop.'
                    : 'Add stock quantity and optional expiry details.',
                onClose: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s2,
                    AppDims.s4,
                    AppDims.s4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SelectedProductBanner(
                        product: _selectedProduct,
                        onClear:
                        widget.initialProduct != null || _selectedProduct == null
                            ? null
                            : _clearSelectedProduct,
                      ),
                      const SizedBox(height: AppDims.s4),
                      if (_selectedProduct == null)
                        _ProductPicker(
                          searchCtrl: _searchCtrl,
                          onSelect: (product) {
                            setState(() => _selectedProduct = product);
                          },
                        )
                      else
                        _StockForm(
                          formKey: _formKey,
                          qtyCtrl: _qtyCtrl,
                          refCtrl: _refCtrl,
                          qtyFocus: _qtyFocus,
                          refFocus: _refFocus,
                          shops: _shopsFromBusiness(context),
                          selectedShop: _selectedShop,
                          lockShop: widget.initialShop != null,
                          movementType: _movementType,
                          selectedExpiryDate: _selectedExpiryDate,
                          onShopChanged: (shop) {
                            setState(() => _selectedShop = shop);
                          },
                          onMovementChanged: (type) {
                            setState(() => _movementType = type);
                          },
                          onExpiryDateChanged: (date) {
                            setState(() => _selectedExpiryDate = date);
                          },
                          onSubmit: _submit,
                        ),
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
}

class _SheetHandle extends StatelessWidget {
  final Color color;

  const _SheetHandle({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s4,
        AppDims.s4,
        AppDims.s2,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              SolarIconsOutline.box,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bs600(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Material(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  SolarIconsOutline.closeCircle,
                  size: 21,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedProductBanner extends StatelessWidget {
  final ProductData? product;
  final VoidCallback? onClear;

  const _SelectedProductBanner({
    required this.product,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (product == null) {
      return _InfoBanner(
        icon: SolarIconsOutline.handStars,
        title: 'Choose product first',
        message: 'Pick a product, then add its opening stock quantity.',
        color: colors.primary,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Icon(
              SolarIconsOutline.bag5,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product!.name ?? 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product!.categoryName?.trim().isNotEmpty == true
                      ? product!.categoryName!.trim()
                      : 'No category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: AppDims.s2),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Change',
                style: AppTextStyles.bs200(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductPicker extends StatefulWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<ProductData> onSelect;

  const _ProductPicker({
    required this.searchCtrl,
    required this.onSelect,
  });

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) {
        return prev.products != curr.products ||
            prev.productStatus != curr.productStatus;
      },
      builder: (context, state) {
        final query = widget.searchCtrl.text.trim().toLowerCase();

        final products = query.isEmpty
            ? state.products
            : state.products.where((product) {
          final name = product.name?.toLowerCase() ?? '';
          final category = product.categoryName?.toLowerCase() ?? '';
          return name.contains(query) || category.contains(query);
        }).toList();

        if (state.productStatus == ProductStatus.loading ||
            state.productStatus == ProductStatus.initial) {
          return const _ProductPickerLoading();
        }

        if (state.productStatus == ProductStatus.failure) {
          return _ProductPickerEmpty(
            icon: SolarIconsOutline.dangerTriangle,
            title: 'Failed to load products',
            message: state.responseError ?? 'Please try again.',
            onRetry: () {
              context.read<ProductBloc>().add(const OnProductInitial());
            },
          );
        }

        if (products.isEmpty) {
          return _ProductPickerEmpty(
            icon: SolarIconsOutline.bag5,
            title: 'No products found',
            message: query.isEmpty
                ? 'Create products first, then you can add stock for them.'
                : 'No product matches your search.',
            onRetry: () {
              context.read<ProductBloc>().add(const OnProductInitial());
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(
              label: 'Product',
              required: true,
            ),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: widget.searchCtrl,
              hint: 'Search products',
              prefixIcon: SolarIconsOutline.magnifier,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: AppDims.s3),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDims.s2),
              itemBuilder: (context, index) {
                final product = products[index];

                return _ProductPickTile(
                  product: product,
                  onTap: () => widget.onSelect(product),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProductPickerLoading extends StatelessWidget {
  const _ProductPickerLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      ),
    );
  }
}

class _ProductPickTile extends StatelessWidget {
  final ProductData product;
  final VoidCallback onTap;

  const _ProductPickTile({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  SolarIconsOutline.bag5,
                  color: colors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.categoryName?.trim().isNotEmpty == true
                          ? product.categoryName!.trim()
                          : 'No category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                SolarIconsOutline.altArrowRight,
                color: colors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPickerEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ProductPickerEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: colors.textHint,
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(SolarIconsOutline.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _StockForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController qtyCtrl;
  final TextEditingController refCtrl;
  final FocusNode qtyFocus;
  final FocusNode refFocus;
  final List<ShopData> shops;
  final ShopData? selectedShop;
  final MovementType movementType;
  final DateTime? selectedExpiryDate;
  final ValueChanged<ShopData> onShopChanged;
  final ValueChanged<MovementType> onMovementChanged;
  final ValueChanged<DateTime?> onExpiryDateChanged;
  final VoidCallback onSubmit;
  final bool lockShop;

  const _StockForm({
    required this.formKey,
    required this.qtyCtrl,
    required this.refCtrl,
    required this.qtyFocus,
    required this.refFocus,
    required this.shops,
    required this.selectedShop,
    required this.movementType,
    required this.onShopChanged,
    required this.onMovementChanged,
    required this.onExpiryDateChanged,
    required this.onSubmit,
    required this.lockShop,
    this.selectedExpiryDate,
  });

  static const _movementTypes = [
    MovementType.opening,
    MovementType.in_,
    MovementType.return_,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (shops.isEmpty) {
      return _InfoEmptyCard(
        icon: SolarIconsOutline.shop,
        title: 'No shops available',
        message: 'Create a shop first before adding product stock.',
      );
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            label: 'Shop',
            required: true,
          ),
          const SizedBox(height: AppDims.s1),
          if (lockShop && selectedShop != null)
            _LockedShopTile(shop: selectedShop!)
          else
            ...shops.map((shop) {
              final selected = selectedShop?.id == shop.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDims.s2),
                child: _SelectableShopTile(
                  shop: shop,
                  selected: selected,
                  onTap: () => onShopChanged(shop),
                ),
              );
            }),

          const SizedBox(height: AppDims.s3),

          FieldLabel(
            label: 'Movement Type',
            required: true,
          ),
          const SizedBox(height: AppDims.s2),
          Wrap(
            spacing: AppDims.s2,
            runSpacing: AppDims.s2,
            children: _movementTypes.map((type) {
              final selected = movementType == type;
              final color = switch (type) {
                MovementType.opening => const Color(0xFF0EA5E9),
                MovementType.in_ => const Color(0xFF16A34A),
                MovementType.return_ => const Color(0xFFEA580C),
                _ => colors.primary,
              };

              return _MovementChip(
                label: type.label,
                color: color,
                selected: selected,
                onTap: () => onMovementChanged(type),
              );
            }).toList(),
          ),

          const SizedBox(height: AppDims.s4),

          _FormPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldLabel(
                  label: 'Quantity',
                  required: true,
                ),
                const SizedBox(height: AppDims.s1),
                AppFormField(
                  controller: qtyCtrl,
                  focusNode: qtyFocus,
                  nextFocus: refFocus,
                  hint: '50',
                  prefixIcon: SolarIconsOutline.addCircle,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    final parsed = double.tryParse(raw);

                    if (raw.isEmpty) {
                      return 'Quantity is required';
                    }

                    if (parsed == null) {
                      return 'Enter a valid number';
                    }

                    if (parsed <= 0) {
                      return 'Must be greater than 0';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppDims.s3),

                FieldLabel(label: 'Reference'),
                const SizedBox(height: AppDims.s1),
                AppFormField(
                  controller: refCtrl,
                  focusNode: refFocus,
                  hint: 'Opening stock / purchase ref',
                  prefixIcon: SolarIconsOutline.tag,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                ),

                const SizedBox(height: AppDims.s3),

                FieldLabel(label: 'Expiry Date'),
                const SizedBox(height: AppDims.s1),
                _ExpiryDatePicker(
                  selected: selectedExpiryDate,
                  onChanged: onExpiryDateChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDims.s5),

          BlocBuilder<InventoryBloc, InventoryState>(
            buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
            builder: (context, state) {
              final isLoading =
                  state.submitStatus == InventorySubmitStatus.loading;

              return SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    disabledBackgroundColor: colors.border,
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
                    'Add Stock',
                    style: AppTextStyles.bs600(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectableShopTile extends StatelessWidget {
  final ShopData shop;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableShopTile({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.shop,
                size: 20,
                color: selected ? colors.primary : colors.textHint,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  shop.name ?? 'Shop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: selected ? colors.primary : colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  SolarIconsOutline.checkCircle,
                  size: 19,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedShopTile extends StatelessWidget {
  final ShopData shop;

  const _LockedShopTile({
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            SolarIconsOutline.lock,
            size: 19,
            color: colors.textHint,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              shop.name ?? 'Shop',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'Selected',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MovementChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.10) : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bs200(context).copyWith(
              color: selected ? color : colors.textSecondary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiryDatePicker extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const _ExpiryDatePicker({
    required this.selected,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selected ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Select expiry date',
    );

    if (date != null) {
      onChanged(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasDate = selected != null;

    final label = hasDate
        ? '${selected!.day.toString().padLeft(2, '0')}/'
        '${selected!.month.toString().padLeft(2, '0')}/'
        '${selected!.year}'
        : 'Optional — tap to select';

    return Material(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.calendar,
                size: 19,
                color: hasDate ? colors.primary : colors.textHint,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: hasDate ? colors.textPrimary : colors.textHint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasDate)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(null),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      SolarIconsOutline.closeCircle,
                      size: 18,
                      color: colors.textHint,
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

class _FormPanel extends StatelessWidget {
  final Widget child;

  const _FormPanel({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.80),
        ),
      ),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colors.textHint,
            size: 38,
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}