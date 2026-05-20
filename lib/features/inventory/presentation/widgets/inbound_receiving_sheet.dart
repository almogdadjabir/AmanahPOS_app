import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showInboundReceivingSheet(BuildContext context) {
  final inventoryBloc = context.read<InventoryBloc>();
  final productBloc = context.read<ProductBloc>();
  final businessBloc = context.read<BusinessBloc>();
  final vendorsBloc = context.read<VendorsBloc>();

  vendorsBloc.add(const OnVendorsStarted());

  if (productBloc.state.products.isEmpty) {
    productBloc.add(const OnProductInitial());
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: inventoryBloc),
        BlocProvider.value(value: productBloc),
        BlocProvider.value(value: businessBloc),
        BlocProvider.value(value: vendorsBloc),
      ],
      child: const _InboundReceivingSheet(),
    ),
  );
}

class _InboundReceivingSheet extends StatefulWidget {
  const _InboundReceivingSheet();

  @override
  State<_InboundReceivingSheet> createState() => _InboundReceivingSheetState();
}

class _InboundReceivingSheetState extends State<_InboundReceivingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ShopData? _selectedShop;
  String? _selectedVendorId;

  final List<_InboundLineInput> _items = [_InboundLineInput()];

  @override
  void initState() {
    super.initState();

    final shops = _shopsFromBusiness(context);
    _selectedShop = shops.isEmpty ? null : shops.first;
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _notesCtrl.dispose();

    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  List<ShopData> _shopsFromBusiness(BuildContext context) {
    final businesses = context.read<BusinessBloc>().state.businessList;
    if (businesses == null || businesses.isEmpty) return const [];
    return businesses.first.shops ?? const [];
  }

  void _addItem() {
    FocusScope.of(context).unfocus();
    setState(() => _items.add(_InboundLineInput()));
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;

    FocusScope.of(context).unfocus();

    final item = _items.removeAt(index);
    item.dispose();

    setState(() {});
  }

  Future<void> _pickVendor(List<VendorData> vendors) async {
    FocusScope.of(context).unfocus();

    if (vendors.isEmpty) {
      GlobalSnackBar.show(
        message: 'No vendors available. Please add a vendor first.',
        isError: true,
      );
      return;
    }

    final selected = await showModalBottomSheet<VendorData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VendorPickerSheet(
        vendors: vendors,
        selectedVendorId: _selectedVendorId,
      ),
    );

    if (!mounted || selected == null) return;

    setState(() => _selectedVendorId = selected.id);
  }

  Future<void> _pickProduct(int index) async {
    FocusScope.of(context).unfocus();

    final productState = context.read<ProductBloc>().state;

    if (productState.productStatus == ProductStatus.loading ||
        productState.productStatus == ProductStatus.initial) {
      GlobalSnackBar.show(
        message: 'Products are still loading...',
        isWarning: true,
      );
      return;
    }

    final products = productState.products;

    if (products.isEmpty) {
      GlobalSnackBar.show(
        message: 'No products loaded',
        isError: true,
      );
      return;
    }

    final picked = await showModalBottomSheet<ProductData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        products: products,
        selectedProductId: _items[index].product?.id,
      ),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _items[index].product = picked;
      _items[index].unitCostCtrl.text = picked.costPrice ?? '';
    });
  }

  Future<void> _pickExpiryDate(_InboundLineInput item) async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiryDate ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 15),
    );

    if (!mounted || picked == null) return;

    setState(() => item.expiryDate = picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final shopId = _selectedShop?.id;
    if (shopId == null || shopId.trim().isEmpty) {
      _showSnack('Please select a shop', isError: true);
      return;
    }

    final vendorId = _selectedVendorId;
    if (vendorId == null || vendorId.trim().isEmpty) {
      _showSnack('Please select a vendor', isError: true);
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    for (final item in _items) {
      if (item.product?.id == null || item.product!.id!.trim().isEmpty) {
        _showSnack('Please select product for all items', isError: true);
        return;
      }
    }

    final request = CreateInboundRequestDto(
      shopId: shopId,
      reference: _referenceCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      vendorId: vendorId,
      items: _items.map((item) {
        return CreateInboundItemRequestDto(
          productId: item.product!.id!,
          quantity: item.quantityCtrl.text.trim(),
          unitCost: item.unitCostCtrl.text.trim().isEmpty
              ? null
              : item.unitCostCtrl.text.trim(),
          expiryDate: item.expiryDate == null ? null : _dateOnly(item.expiryDate!),
          batchNumber: item.batchCtrl.text.trim().isEmpty
              ? null
              : item.batchCtrl.text.trim(),
        );
      }).toList(),
    );

    context.read<InventoryBloc>().add(
      OnCreateInboundTransaction(request: request),
    );
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showSnack(String message, {bool isError = false}) {
    GlobalSnackBar.show(
      message: message,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return BlocListener<InventoryBloc, InventoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == InventorySubmitStatus.success ||
            state.submitStatus == InventorySubmitStatus.queued) {
          Navigator.of(context).maybePop();

          _showSnack(
            state.submitStatus == InventorySubmitStatus.queued
                ? 'Inbound saved offline. It will sync when internet is back.'
                : 'Inbound stock received successfully',
          );

          context.read<InventoryBloc>().add(
            const OnAcknowledgeInventorySubmit(),
          );
        }

        if (state.submitStatus == InventorySubmitStatus.failure) {
          _showSnack(
            state.submitError ?? 'Failed to receive inbound stock',
            isError: true,
          );

          context.read<InventoryBloc>().add(
            const OnAcknowledgeInventorySubmit(),
          );
        }
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.94,
          minChildSize: 0.72,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, sheetScrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDims.rXl),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: AppDims.s3),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  _Header(onClose: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: sheetScrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          AppDims.s4,
                          AppDims.s2,
                          AppDims.s4,
                          AppDims.s6 + bottomSafe,
                        ),
                        children: [
                          _PremiumIntroCard(itemCount: _items.length),
                          const SizedBox(height: AppDims.s4),

                          BlocBuilder<VendorsBloc, VendorsState>(
                            buildWhen: (p, c) =>
                            p.status != c.status ||
                                p.vendors != c.vendors ||
                                p.responseError != c.responseError,
                            builder: (context, vendorState) {
                              return _ReferenceCard(
                                referenceCtrl: _referenceCtrl,
                                notesCtrl: _notesCtrl,
                                shops: _shopsFromBusiness(context),
                                selectedShop: _selectedShop,
                                onShopChanged: (shop) {
                                  setState(() => _selectedShop = shop);
                                },
                                vendorsStatus: vendorState.status,
                                vendors: vendorState.vendors,
                                selectedVendorId: _selectedVendorId,
                                vendorError: vendorState.responseError,
                                onPickVendor: () {
                                  _pickVendor(vendorState.vendors);
                                },
                                onRetryVendors: () {
                                  context.read<VendorsBloc>().add(
                                    const OnVendorsStarted(),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: AppDims.s4),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Inbound items',
                                  style: AppTextStyles.bs500(context).copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(
                                  SolarIconsOutline.addCircle,
                                  size: 18,
                                ),
                                label: const Text('Add item'),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDims.s2),

                          BlocBuilder<ProductBloc, ProductState>(
                            buildWhen: (p, c) =>
                            p.productStatus != c.productStatus ||
                                p.products.length != c.products.length,
                            builder: (context, productState) {
                              final isProductLoading =
                                  productState.productStatus == ProductStatus.loading ||
                                      productState.productStatus == ProductStatus.initial;

                              if (isProductLoading && productState.products.isEmpty) {
                                return const _InlineLoadingCard(
                                  title: 'Loading products...',
                                  subtitle: 'Preparing product list for receiving.',
                                  icon: SolarIconsOutline.bag5,
                                );
                              }

                              if (productState.products.isEmpty) {
                                return _InlineMessageCard(
                                  title: 'No products found',
                                  subtitle:
                                  'Create products first before receiving stock.',
                                  icon: SolarIconsOutline.bag5,
                                  actionLabel: 'Retry',
                                  onAction: () {
                                    context.read<ProductBloc>().add(
                                      const OnProductInitial(),
                                    );
                                  },
                                );
                              }

                              return Column(
                                children: List.generate(_items.length, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppDims.s3,
                                    ),
                                    child: _InboundItemCard(
                                      index: i,
                                      item: _items[i],
                                      canRemove: _items.length > 1,
                                      onRemove: () => _removeItem(i),
                                      onPickProduct: () => _pickProduct(i),
                                      onPickExpiry: () => _pickExpiryDate(_items[i]),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  _SubmitBar(
                    bottomSafe: bottomSafe,
                    onSubmit: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InboundLineInput {
  ProductData? product;
  DateTime? expiryDate;

  final quantityCtrl = TextEditingController(text: '1');
  final unitCostCtrl = TextEditingController();
  final batchCtrl = TextEditingController();

  void dispose() {
    quantityCtrl.dispose();
    unitCostCtrl.dispose();
    batchCtrl.dispose();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s2,
        AppDims.s2,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
            child: Icon(
              SolarIconsOutline.box,
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
                  'Inbound Receiving',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Receive supplier stock with one auditable reference.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              SolarIconsOutline.closeCircle,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumIntroCard extends StatelessWidget {
  final int itemCount;

  const _PremiumIntroCard({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
            child: Icon(
              SolarIconsOutline.box,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium stock receiving',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} under one reference.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
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

class _ReferenceCard extends StatelessWidget {
  final TextEditingController referenceCtrl;
  final TextEditingController notesCtrl;

  final List<ShopData> shops;
  final ShopData? selectedShop;
  final ValueChanged<ShopData?> onShopChanged;

  final VendorsStatus vendorsStatus;
  final List<VendorData> vendors;
  final String? selectedVendorId;
  final String? vendorError;
  final VoidCallback onPickVendor;
  final VoidCallback onRetryVendors;

  const _ReferenceCard({
    required this.referenceCtrl,
    required this.notesCtrl,
    required this.shops,
    required this.selectedShop,
    required this.onShopChanged,
    required this.vendorsStatus,
    required this.vendors,
    required this.selectedVendorId,
    required this.vendorError,
    required this.onPickVendor,
    required this.onRetryVendors,
  });

  VendorData? get _selectedVendor {
    for (final vendor in vendors) {
      if (vendor.id == selectedVendorId) return vendor;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selectedVendor = _selectedVendor;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: 'Reference', required: true),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller: referenceCtrl,
            hint: 'PO-2026-0001',
            prefixIcon: SolarIconsOutline.notes,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Reference is required';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'Shop', required: true),
          const SizedBox(height: AppDims.s1),
          DropdownButtonFormField<ShopData>(
            value: selectedShop,
            isExpanded: true,
            items: shops.map((shop) {
              return DropdownMenuItem<ShopData>(
                value: shop,
                child: Text(
                  shop.name ?? 'Shop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onShopChanged,
            validator: (value) => value == null ? 'Shop is required' : null,
            decoration: _dropdownDecoration(
              context: context,
              icon: SolarIconsOutline.shop,
              hint: shops.isEmpty ? 'No shops available' : 'Select shop',
            ),
          ),

          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'Vendor', required: true),
          const SizedBox(height: AppDims.s1),
          _VendorSelectorField(
            status: vendorsStatus,
            selectedVendor: selectedVendor,
            vendorCount: vendors.length,
            error: vendorError,
            onTap: onPickVendor,
            onRetry: onRetryVendors,
          ),

          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'Notes'),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller: notesCtrl,
            hint: 'Supplier delivery note',
            prefixIcon: SolarIconsOutline.notes,
            textInputAction: TextInputAction.newline,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required BuildContext context,
    required IconData icon,
    required String hint,
  }) {
    final colors = context.appColors;

    return InputDecoration(
      filled: true,
      fillColor: colors.surfaceSoft,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 18,
        color: colors.textHint,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDims.rMd),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDims.rMd),
        borderSide: BorderSide(color: colors.border),
      ),
    );
  }
}

class _VendorSelectorField extends StatelessWidget {
  final VendorsStatus status;
  final VendorData? selectedVendor;
  final int vendorCount;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _VendorSelectorField({
    required this.status,
    required this.selectedVendor,
    required this.vendorCount,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isLoading = status == VendorsStatus.loading && vendorCount == 0;
    final hasFailure = status == VendorsStatus.failure && vendorCount == 0;
    final isEmpty = status == VendorsStatus.success && vendorCount == 0;

    if (isLoading) {
      return const _PickerLikeField(
        title: 'Loading vendors...',
        subtitle: 'Preparing supplier list',
        icon: SolarIconsOutline.buildings,
        trailing: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (hasFailure) {
      return _PickerLikeField(
        title: 'Could not load vendors',
        subtitle: error ?? 'Tap retry to load suppliers again',
        icon: SolarIconsOutline.buildings,
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      );
    }

    if (isEmpty) {
      return _PickerLikeField(
        title: 'No vendors available',
        subtitle: 'Create a vendor first, then receive stock',
        icon: SolarIconsOutline.buildings,
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Refresh'),
        ),
      );
    }

    return FormField<String>(
      initialValue: selectedVendor?.id,
      validator: (_) {
        if (selectedVendor == null || selectedVendor!.id.trim().isEmpty) {
          return 'Vendor is required';
        }
        return null;
      },
      builder: (field) {
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppDims.rMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s3,
                    vertical: AppDims.s2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: hasError ? colors.danger : colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        SolarIconsOutline.buildings,
                        size: 18,
                        color: hasError ? colors.danger : colors.textHint,
                      ),
                      const SizedBox(width: AppDims.s2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedVendor?.name.trim().isNotEmpty == true
                                  ? selectedVendor!.name.trim()
                                  : 'Select vendor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs300(context).copyWith(
                                color: selectedVendor == null
                                    ? colors.textHint
                                    : colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (selectedVendor?.phone?.trim().isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  selectedVendor!.phone!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bs100(context).copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDims.s2),
                      Icon(
                        SolarIconsOutline.altArrowDown,
                        color: colors.textHint,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InboundItemCard extends StatelessWidget {
  final int index;
  final _InboundLineInput item;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onPickExpiry;

  const _InboundItemCard({
    required this.index,
    required this.item,
    required this.canRemove,
    required this.onRemove,
    required this.onPickProduct,
    required this.onPickExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final product = item.product;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  'Inbound item',
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    SolarIconsOutline.trashBinTrash,
                    color: colors.danger,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'Product', required: true),
          const SizedBox(height: AppDims.s1),
          if (product == null)
            _PickerLikeButton(
              title: 'Select product',
              subtitle: 'Search by name, SKU, or barcode',
              icon: SolarIconsOutline.bag5,
              onTap: onPickProduct,
            )
          else
            _SelectedProductRow(
              product: product,
              onChange: onPickProduct,
            ),

          const SizedBox(height: AppDims.s3),

          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;

              final quantityField = _SmallInputBlock(
                label: 'Quantity',
                required: true,
                child: AppFormField(
                  controller: item.quantityCtrl,
                  hint: '10',
                  prefixIcon: SolarIconsOutline.addCircle,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validatePositiveNumber,
                ),
              );

              final costField = _SmallInputBlock(
                label: 'Unit cost',
                child: AppFormField(
                  controller: item.unitCostCtrl,
                  hint: '0.00',
                  prefixIcon: SolarIconsOutline.walletMoney,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateOptionalMoney,
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    quantityField,
                    const SizedBox(height: AppDims.s3),
                    costField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: quantityField),
                  const SizedBox(width: AppDims.s3),
                  Expanded(child: costField),
                ],
              );
            },
          ),

          const SizedBox(height: AppDims.s3),

          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;

              final expiryField = _SmallInputBlock(
                label: 'Expiry date',
                child: _DatePickerField(
                  date: item.expiryDate,
                  onTap: onPickExpiry,
                ),
              );

              final batchField = _SmallInputBlock(
                label: 'Batch',
                child: AppFormField(
                  controller: item.batchCtrl,
                  hint: 'BATCH-A',
                  prefixIcon: SolarIconsOutline.tag,
                  textInputAction: TextInputAction.done,
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    expiryField,
                    const SizedBox(height: AppDims.s3),
                    batchField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: expiryField),
                  const SizedBox(width: AppDims.s3),
                  Expanded(child: batchField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String? _validatePositiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Required';
    if (parsed <= 0) return 'Must be > 0';
    return null;
  }

  static String? _validateOptionalMoney(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);
    if (parsed == null) return 'Invalid';
    if (parsed < 0) return 'Invalid';

    return null;
  }
}

class _SmallInputBlock extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _SmallInputBlock({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, required: required),
        const SizedBox(height: AppDims.s1),
        child,
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.date,
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
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.calendar,
                color: colors.textHint,
                size: 18,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  date == null ? 'Optional' : _formatDate(date!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: date == null ? colors.textHint : colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _SelectedProductRow extends StatelessWidget {
  final ProductData product;
  final VoidCallback onChange;

  const _SelectedProductRow({
    required this.product,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.bag5,
                color: colors.primary,
                size: 23,
              ),
              const SizedBox(width: AppDims.s2),
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
                    const SizedBox(height: 2),
                    Text(
                      product.sku?.trim().isNotEmpty == true
                          ? product.sku!.trim()
                          : 'Tap to change product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Text(
                'Change',
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final double bottomSafe;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.bottomSafe,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (p, c) => p.submitStatus != c.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == InventorySubmitStatus.loading;

        return Container(
          padding: EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s4,
            bottomSafe + AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: colors.border.withValues(alpha: 0.8),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rXl),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(SolarIconsOutline.box, size: 22),
                  const SizedBox(width: AppDims.s2),
                  Text(
                    'Receive Stock',
                    style: AppTextStyles.bs300(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VendorPickerSheet extends StatefulWidget {
  final List<VendorData> vendors;
  final String? selectedVendorId;

  const _VendorPickerSheet({
    required this.vendors,
    required this.selectedVendorId,
  });

  @override
  State<_VendorPickerSheet> createState() => _VendorPickerSheetState();
}

class _VendorPickerSheetState extends State<_VendorPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<VendorData> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = _initialVisibleVendors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VendorData> _initialVisibleVendors() {
    final active = widget.vendors
        .where((vendor) => vendor.id.trim().isNotEmpty && vendor.isActive)
        .toList();

    if (active.length <= 80) return active;
    return active.take(80).toList();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filtered = _initialVisibleVendors());
      return;
    }

    final results = <VendorData>[];

    for (final vendor in widget.vendors) {
      if (vendor.id.trim().isEmpty || !vendor.isActive) continue;

      final name = vendor.name.toLowerCase();
      final phone = (vendor.phone ?? '').toLowerCase();
      final email = (vendor.email ?? '').toLowerCase();

      if (name.contains(query) ||
          phone.contains(query) ||
          email.contains(query)) {
        results.add(vendor);
      }

      if (results.length >= 80) break;
    }

    setState(() => _filtered = results);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.46,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                _PickerHeader(
                  title: 'Select Vendor',
                  subtitle: 'Choose the supplier for this receipt',
                  icon: SolarIconsOutline.buildings,
                  onClose: () => Navigator.pop(context),
                ),
                _PickerSearchField(
                  controller: _searchCtrl,
                  hint: 'Search vendor by name, phone, or email',
                  onChanged: _onSearchChanged,
                ),
                _PickerCounter(
                  leftText: '${_filtered.length} vendors',
                  rightText: widget.vendors.length > 80 ? 'Search to find more' : null,
                ),
                const Divider(height: 1),
                Expanded(
                  child: _filtered.isEmpty
                      ? _PickerEmptyState(
                    title: 'No vendors found',
                    subtitle: 'Try another search keyword.',
                    icon: SolarIconsOutline.buildings,
                  )
                      : ListView.separated(
                    controller: scrollController,
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppDims.s4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDims.s2),
                    itemBuilder: (context, index) {
                      final vendor = _filtered[index];
                      final isSelected =
                          vendor.id == widget.selectedVendorId;

                      return _VendorTile(
                        vendor: vendor,
                        isSelected: isSelected,
                        onTap: () => Navigator.pop(context, vendor),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<ProductData> products;
  final String? selectedProductId;

  const _ProductPickerSheet({
    required this.products,
    required this.selectedProductId,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<ProductData> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = _initialVisibleProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductData> _initialVisibleProducts() {
    final valid = widget.products
        .where((product) => product.id?.trim().isNotEmpty == true)
        .toList();

    if (valid.length <= 80) return valid;
    return valid.take(80).toList();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filtered = _initialVisibleProducts());
      return;
    }

    final results = <ProductData>[];

    for (final product in widget.products) {
      if (product.id?.trim().isNotEmpty != true) continue;

      final name = (product.name ?? '').toLowerCase();
      final sku = (product.sku ?? '').toLowerCase();
      final barcode = (product.barcode ?? '').toLowerCase();

      if (name.contains(query) ||
          sku.contains(query) ||
          barcode.contains(query)) {
        results.add(product);
      }

      if (results.length >= 80) break;
    }

    setState(() => _filtered = results);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.50,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                _PickerHeader(
                  title: 'Select Product',
                  subtitle: 'Choose the item you received',
                  icon: SolarIconsOutline.bag5,
                  onClose: () => Navigator.pop(context),
                ),
                _PickerSearchField(
                  controller: _searchCtrl,
                  hint: 'Search by name, SKU, or barcode',
                  onChanged: _onSearchChanged,
                ),
                _PickerCounter(
                  leftText: '${_filtered.length} products',
                  rightText: widget.products.length > 80 ? 'Search to find more' : null,
                ),
                const Divider(height: 1),
                Expanded(
                  child: _filtered.isEmpty
                      ? _PickerEmptyState(
                    title: 'No products found',
                    subtitle: 'Try another search keyword.',
                    icon: SolarIconsOutline.bag5,
                  )
                      : ListView.separated(
                    controller: scrollController,
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppDims.s4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDims.s2),
                    itemBuilder: (context, index) {
                      final product = _filtered[index];
                      final isSelected =
                          product.id == widget.selectedProductId;

                      return _ProductTile(
                        product: product,
                        isSelected: isSelected,
                        onTap: () => Navigator.pop(context, product),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;

  const _PickerHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              SolarIconsOutline.closeCircle,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _PickerSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s2,
      ),
      child: TextField(
        controller: controller,
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            SolarIconsOutline.magnifier,
            color: colors.textSecondary,
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            onPressed: () {
              controller.clear();
              onChanged('');
            },
            icon: Icon(
              SolarIconsOutline.closeCircle,
              color: colors.textSecondary,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: colors.textSecondary.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _PickerCounter extends StatelessWidget {
  final String leftText;
  final String? rightText;

  const _PickerCounter({
    required this.leftText,
    this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        0,
        AppDims.s4,
        AppDims.s2,
      ),
      child: Row(
        children: [
          Text(
            leftText,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (rightText != null)
            Text(
              rightText!,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  final VendorData vendor;
  final bool isSelected;
  final VoidCallback onTap;

  const _VendorTile({
    required this.vendor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: isSelected
          ? colors.primary.withValues(alpha: 0.09)
          : colors.surfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  SolarIconsOutline.buildings,
                  color: colors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name.trim().isEmpty
                          ? 'Unnamed vendor'
                          : vendor.name.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (vendor.phone?.trim().isNotEmpty == true)
                          vendor.phone!.trim(),
                        if (vendor.email?.trim().isNotEmpty == true)
                          vendor.email!.trim(),
                      ].join(' · ').isEmpty
                          ? 'No contact details'
                          : [
                        if (vendor.phone?.trim().isNotEmpty == true)
                          vendor.phone!.trim(),
                        if (vendor.email?.trim().isNotEmpty == true)
                          vendor.email!.trim(),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                isSelected
                    ? SolarIconsOutline.checkCircle
                    : SolarIconsOutline.altArrowRight,
                size: 19,
                color: isSelected ? colors.primary : colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductData product;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: isSelected
          ? colors.primary.withValues(alpha: 0.09)
          : colors.surfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  SolarIconsOutline.bag5,
                  color: colors.primary,
                  size: 19,
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
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (product.sku?.trim().isNotEmpty == true)
                          'SKU: ${product.sku!.trim()}',
                        if (product.barcode?.trim().isNotEmpty == true)
                          'Barcode: ${product.barcode!.trim()}',
                      ].join(' · ').isEmpty
                          ? 'No SKU or barcode'
                          : [
                        if (product.sku?.trim().isNotEmpty == true)
                          'SKU: ${product.sku!.trim()}',
                        if (product.barcode?.trim().isNotEmpty == true)
                          'Barcode: ${product.barcode!.trim()}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                isSelected
                    ? SolarIconsOutline.checkCircle
                    : SolarIconsOutline.altArrowRight,
                size: 19,
                color: isSelected ? colors.primary : colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerLikeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerLikeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
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
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: colors.textHint,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                SolarIconsOutline.altArrowDown,
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

class _PickerLikeField extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  const _PickerLikeField({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: colors.textHint,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s2),
          trailing,
        ],
      ),
    );
  }
}

class _InlineLoadingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InlineLoadingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(width: AppDims.s3),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineMessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textHint, size: 24),
          const SizedBox(width: AppDims.s3),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppDims.s2),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PickerEmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 42,
              color: colors.textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}