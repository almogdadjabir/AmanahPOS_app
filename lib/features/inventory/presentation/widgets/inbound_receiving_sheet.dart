import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showInboundReceivingSheet(BuildContext context) {
  final inventoryBloc = context.read<InventoryBloc>();
  final productBloc = context.read<ProductBloc>();
  final businessBloc = context.read<BusinessBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: inventoryBloc),
        BlocProvider.value(value: productBloc),
        BlocProvider.value(value: businessBloc),
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
  final _searchCtrl = TextEditingController();

  ShopData? _selectedShop;
  final List<_InboundLineInput> _items = [_InboundLineInput()];

  @override
  void initState() {
    super.initState();

    final shops = _shopsFromBusiness(context);
    _selectedShop = shops.isEmpty ? null : shops.first;

    final productState = context.read<ProductBloc>().state;
    if (productState.products.isEmpty) {
      context.read<ProductBloc>().add(const OnProductInitial());
    }
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
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
    setState(() => _items.add(_InboundLineInput()));
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    final item = _items.removeAt(index);
    item.dispose();
    setState(() {});
  }

  Future<void> _pickExpiryDate(_InboundLineInput item) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiryDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 15),
    );

    if (picked == null) return;
    setState(() => item.expiryDate = picked);
  }

  void _submit() {
    final shopId = _selectedShop?.id;
    if (shopId == null || shopId.trim().isEmpty) {
      _showSnack('Please select a shop', isError: true);
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    for (final item in _items) {
      if (item.product == null) {
        _showSnack('Please select product for all items', isError: true);
        return;
      }
    }

    final request = CreateInboundRequestDto(
      shopId: shopId,
      reference: _referenceCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      items: _items.map((item) {
        return CreateInboundItemRequestDto(
          productId: item.product!.id!,
          quantity: item.quantityCtrl.text.trim(),
          unitCost: item.unitCostCtrl.text.trim(),
          expiryDate: item.expiryDate == null ? null : _dateOnly(item.expiryDate!),
          batchNumber: item.batchCtrl.text.trim(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.appColors.danger : context.appColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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

          context.read<InventoryBloc>().add(const OnAcknowledgeInventorySubmit());
        }

        if (state.submitStatus == InventorySubmitStatus.failure) {
          _showSnack(
            state.submitError ?? 'Failed to receive inbound stock',
            isError: true,
          );
          context.read<InventoryBloc>().add(const OnAcknowledgeInventorySubmit());
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.94,
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
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              _Header(onClose: () => Navigator.of(context).pop()),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s2,
                      AppDims.s4,
                      AppDims.s4,
                    ),
                    children: [
                      _PremiumIntroCard(itemCount: _items.length),
                      const SizedBox(height: AppDims.s4),
                      _ReferenceCard(
                        referenceCtrl: _referenceCtrl,
                        notesCtrl: _notesCtrl,
                        shops: _shopsFromBusiness(context),
                        selectedShop: _selectedShop,
                        onShopChanged: (shop) => setState(() => _selectedShop = shop),
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
                            icon: const Icon(SolarIconsOutline.addCircle, size: 18),
                            label: const Text('Add item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDims.s2),
                      for (var i = 0; i < _items.length; i++) ...[
                        _InboundItemCard(
                          index: i,
                          item: _items[i],
                          searchCtrl: _searchCtrl,
                          canRemove: _items.length > 1,
                          onRemove: () => _removeItem(i),
                          onSelectProduct: (product) {
                            setState(() {
                              _items[i].product = product;
                              _items[i].unitCostCtrl.text = product.costPrice ?? '';
                            });
                          },
                          onPickExpiry: () => _pickExpiryDate(_items[i]),
                        ),
                        const SizedBox(height: AppDims.s3),
                      ],
                      BlocBuilder<InventoryBloc, InventoryState>(
                        buildWhen: (p, c) => p.submitStatus != c.submitStatus,
                        builder: (context, state) {
                          final isLoading = state.submitStatus == InventorySubmitStatus.loading;
                          return SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
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
                          );
                        },
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

class _InboundLineInput {
  ProductData? product;
  DateTime? expiryDate;
  final quantityCtrl = TextEditingController();
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
      padding: const EdgeInsets.fromLTRB(AppDims.s4, AppDims.s3, AppDims.s2, AppDims.s2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inbound Receiving',
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Receive supplier stock with one shared reference.',
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
            icon: Icon(SolarIconsOutline.closeCircle, color: colors.textHint),
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
        border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
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
            child: Icon(SolarIconsOutline.box, color: colors.primary, size: 28),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium stock receiving',
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} under one auditable reference.',
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

  const _ReferenceCard({
    required this.referenceCtrl,
    required this.notesCtrl,
    required this.shops,
    required this.selectedShop,
    required this.onShopChanged,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: 'Reference', required: true),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller: referenceCtrl,
            hint: 'PO-2026-0001',
            prefixIcon: SolarIconsOutline.notes,
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
            items: shops.map((shop) {
              return DropdownMenuItem(
                value: shop,
                child: Text(shop.name ?? 'Shop'),
              );
            }).toList(),
            onChanged: onShopChanged,
            validator: (value) => value == null ? 'Shop is required' : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surfaceSoft,
              prefixIcon: Icon(SolarIconsOutline.shop, size: 18, color: colors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          const SizedBox(height: AppDims.s3),
          FieldLabel(label: 'Notes'),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller: notesCtrl,
            hint: 'Supplier delivery note',
            prefixIcon: SolarIconsOutline.notes,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _InboundItemCard extends StatelessWidget {
  final int index;
  final _InboundLineInput item;
  final TextEditingController searchCtrl;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<ProductData> onSelectProduct;
  final VoidCallback onPickExpiry;

  const _InboundItemCard({
    required this.index,
    required this.item,
    required this.searchCtrl,
    required this.canRemove,
    required this.onRemove,
    required this.onSelectProduct,
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
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(SolarIconsOutline.trashBinTrash, color: colors.danger),
                ),
            ],
          ),
          const SizedBox(height: AppDims.s2),
          if (product == null)
            _ProductSelector(
              searchCtrl: searchCtrl,
              onSelect: onSelectProduct,
            )
          else
            _SelectedProductRow(
              product: product,
              onChange: () => onSelectProduct(product.copyWith()),
            ),
          const SizedBox(height: AppDims.s3),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(label: 'Quantity', required: true),
                    const SizedBox(height: AppDims.s1),
                    AppFormField(
                      controller: item.quantityCtrl,
                      hint: '10',
                      prefixIcon: SolarIconsOutline.addCircle,
                      keyboardType: TextInputType.number,
                      validator: _validatePositiveNumber,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(label: 'Unit cost'),
                    const SizedBox(height: AppDims.s1),
                    AppFormField(
                      controller: item.unitCostCtrl,
                      hint: '0.00',
                      prefixIcon: SolarIconsOutline.walletMoney,
                      keyboardType: TextInputType.number,
                      validator: _validateOptionalMoney,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s3),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(label: 'Expiry date'),
                    const SizedBox(height: AppDims.s1),
                    InkWell(
                      onTap: onPickExpiry,
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(SolarIconsOutline.calendar, color: colors.textHint, size: 18),
                            const SizedBox(width: AppDims.s2),
                            Expanded(
                              child: Text(
                                item.expiryDate == null ? 'Optional' : _formatDate(item.expiryDate!),
                                style: AppTextStyles.bs300(context).copyWith(
                                  color: item.expiryDate == null ? colors.textHint : colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(label: 'Batch'),
                    const SizedBox(height: AppDims.s1),
                    AppFormField(
                      controller: item.batchCtrl,
                      hint: 'BATCH-A',
                      prefixIcon: SolarIconsOutline.tag,
                    ),
                  ],
                ),
              ),
            ],
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

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _ProductSelector extends StatefulWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<ProductData> onSelect;

  const _ProductSelector({
    required this.searchCtrl,
    required this.onSelect,
  });

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (p, c) => p.products != c.products || p.productStatus != c.productStatus,
      builder: (context, state) {
        if (state.productStatus == ProductStatus.loading ||
            state.productStatus == ProductStatus.initial) {
          return Center(child: CircularProgressIndicator(color: colors.primary));
        }

        final q = widget.searchCtrl.text.trim().toLowerCase();
        final products = state.products.where((p) {
          if (p.id == null || p.id!.isEmpty) return false;
          if (q.isEmpty) return true;
          return (p.name ?? '').toLowerCase().contains(q) ||
              (p.sku ?? '').toLowerCase().contains(q) ||
              (p.barcode ?? '').toLowerCase().contains(q);
        }).take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(label: 'Product', required: true),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: widget.searchCtrl,
              hint: 'Search by name, SKU, or barcode',
              prefixIcon: SolarIconsOutline.magnifier,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: AppDims.s2),
            if (products.isEmpty)
              Text(
                'No product found',
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              ...products.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDims.s2),
                    child: _ProductTile(
                      product: product,
                      onTap: () => widget.onSelect(product),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductData product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

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
              Icon(SolarIconsOutline.bag5, color: colors.primary, size: 22),
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
                    Text(
                      [product.sku, product.barcode].where((e) => e != null && e.trim().isNotEmpty).join(' • '),
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
              Icon(SolarIconsOutline.altArrowRight, color: colors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedProductRow extends StatelessWidget {
  final ProductData product;
  final VoidCallback onChange;

  const _SelectedProductRow({required this.product, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(SolarIconsOutline.bag5, color: colors.primary, size: 23),
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
                Text(
                  product.sku?.trim().isNotEmpty == true ? product.sku!.trim() : 'No SKU',
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
          TextButton(
            onPressed: () {},
            child: const Text('Selected'),
          ),
        ],
      ),
    );
  }
}
