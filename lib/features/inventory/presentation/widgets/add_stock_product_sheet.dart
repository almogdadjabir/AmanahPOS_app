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

void showAddStockProductSheet(
    BuildContext context, {
      ProductData? initialProduct,
      Shops? initialShop,
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
  final Shops? initialShop;

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
  Shops? _selectedShop;
  MovementType _movementType = MovementType.opening;

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

  Shops? _firstValidShop(List<Shops> shops) {
    for (final shop in shops) {
      final id = shop.id;
      if (id != null && id.trim().isNotEmpty) {
        return shop;
      }
    }

    return null;
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

  List<Shops> _shopsFromBusiness(BuildContext context) {
    final businessState = context.read<BusinessBloc>().state;

    final businesses = businessState.businessList;
    if (businesses == null || businesses.isEmpty) return const [];

    return businesses.first.shops ?? const [];
  }

  void _submit() {
    final productId = _selectedProduct?.id;
    final shopId = _selectedShop?.id;

    if (productId == null) {
      GlobalSnackBar.show(
        message: 'Please select a product',
        isError: true,
      );
      return;
    }

    if (shopId == null) {
      GlobalSnackBar.show(
        message: 'Please select a shop',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    context.read<InventoryBloc>().add(
      OnAddStock(
        productId: productId,
        shopId: shopId,
        quantity: _qtyCtrl.text.trim(),
        movementType: _movementType,
        reference: _refCtrl.text.trim().isEmpty
            ? null
            : _refCtrl.text.trim(),
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
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
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
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s2,
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
                        Icons.inventory_2_rounded,
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
                            'Add Stock',
                            style: AppTextStyles.bs600(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            _selectedProduct == null
                                ? 'Select a product and assign quantity to a shop.'
                                : 'Add stock for this product.',
                            style: AppTextStyles.bs200(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectedProductBanner(
                        product: _selectedProduct,
                        onClear: widget.initialProduct != null || _selectedProduct == null
                            ? null
                            : () {
                          setState(() {
                            _selectedProduct = null;
                            _selectedShop = null;
                            _qtyCtrl.clear();
                            _refCtrl.clear();
                          });
                        },
                      ),
                      const SizedBox(height: AppDims.s3),
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
                          lockShop: widget.initialProduct != null,
                          movementType: _movementType,
                          onShopChanged: (shop) {
                            setState(() => _selectedShop = shop);
                          },
                          onMovementChanged: (type) {
                            setState(() => _movementType = type);
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: colors.primary, size: 18),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                'Choose a product first, then add its opening stock.',
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, color: colors.primary, size: 20),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              product!.name ?? 'Product',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text('Change'),
            ),
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

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onSearchChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) =>
      prev.products != curr.products ||
          prev.productStatus != curr.productStatus,
      builder: (context, state) {
        final query = widget.searchCtrl.text.trim().toLowerCase();

        final products = query.isEmpty
            ? state.products
            : state.products.where((p) {
          final name = p.name?.toLowerCase() ?? '';
          final category = p.categoryName?.toLowerCase() ?? '';
          return name.contains(query) || category.contains(query);
        }).toList();

        if (state.productStatus == ProductStatus.loading ||
            state.productStatus == ProductStatus.initial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDims.s5),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.productStatus == ProductStatus.failure) {
          return _ProductPickerEmpty(
            title: 'Failed to load products',
            message: state.responseError ?? 'Please try again.',
            onRetry: () {
              context.read<ProductBloc>().add(const OnProductInitial());
            },
          );
        }

        if (products.isEmpty) {
          return _ProductPickerEmpty(
            title: 'No products found',
            message: 'Create products first, then you can add stock for them.',
            onRetry: () {
              context.read<ProductBloc>().add(const OnProductInitial());
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(label: 'Product', required: true),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: widget.searchCtrl,
              hint: 'Search products',
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: AppDims.s3),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDims.s2),
              itemBuilder: (context, index) {
                return _ProductPickTile(
                  product: products[index],
                  onTap: () => widget.onSelect(products[index]),
                );
              },
            ),
          ],
        );
      },
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
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
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
                      product.name ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      product.categoryName?.trim().isNotEmpty == true
                          ? product.categoryName!.trim()
                          : 'No category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPickerEmpty extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ProductPickerEmpty({
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
      ),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined, size: 36, color: colors.textHint),
          const SizedBox(height: AppDims.s3),
          Text(
            title,
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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
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
  final List<Shops> shops;
  final Shops? selectedShop;
  final MovementType movementType;
  final ValueChanged<Shops> onShopChanged;
  final ValueChanged<MovementType> onMovementChanged;
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
    required this.onSubmit,
    required this.lockShop,
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDims.s4),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, color: colors.textHint, size: 34),
            const SizedBox(height: AppDims.s3),
            Text(
              'No shops available',
              style: AppTextStyles.bs500(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppDims.s1),
            Text(
              'Create a shop first before adding product stock.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: 'Shop', required: true),
          const SizedBox(height: AppDims.s1),

          if (lockShop && selectedShop != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDims.s2),
              padding: const EdgeInsets.all(AppDims.s3),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rMd),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: colors.textHint,
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      selectedShop?.name ?? 'Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Default',
                    style: AppTextStyles.bs100(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            ...shops.map((shop) {
              final selected = selectedShop?.id == shop.id;

              return GestureDetector(
                onTap: () => onShopChanged(shop),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: AppDims.s2),
                  padding: const EdgeInsets.all(AppDims.s3),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.08)
                        : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 18,
                        color: selected ? colors.primary : colors.textHint,
                      ),
                      const SizedBox(width: AppDims.s2),
                      Expanded(
                        child: Text(
                          shop.name ?? 'Shop',
                          style: AppTextStyles.bs300(context).copyWith(
                            color: selected ? colors.primary : colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: AppDims.s3),
          FieldLabel(label: 'Movement Type', required: true),
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

              return GestureDetector(
                onTap: () => onMovementChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s3,
                    vertical: AppDims.s2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.10)
                        : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: selected ? color : colors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: selected ? color : colors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDims.s3),
          FieldLabel(label: 'Quantity', required: true),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller: qtyCtrl,
            focusNode: qtyFocus,
            nextFocus: refFocus,
            hint: '50',
            prefixIcon: Icons.add_circle_outline_rounded,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (v) {
              final value = double.tryParse(v?.trim() ?? '');
              if (v == null || v.trim().isEmpty) {
                return 'Quantity is required';
              }
              if (value == null) {
                return 'Enter a valid number';
              }
              if (value <= 0) {
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
            prefixIcon: Icons.tag_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: AppDims.s5),
          BlocBuilder<InventoryBloc, InventoryState>(
            buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
            builder: (context, state) {
              final isLoading =
                  state.submitStatus == InventorySubmitStatus.loading;

              return SizedBox(
                width: double.infinity,
                height: 50,
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