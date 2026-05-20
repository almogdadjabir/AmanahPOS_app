import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inbound_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showInboundSheet(BuildContext context) {
  final inboundBloc = context.read<InboundBloc>();
  final vendorsBloc = context.read<VendorsBloc>();
  final productBloc = context.read<ProductBloc>();
  final authBloc = context.read<AuthBloc>();

  inboundBloc.add(const OnInboundStarted());

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: inboundBloc),
        BlocProvider.value(value: vendorsBloc),
        BlocProvider.value(value: productBloc),
        BlocProvider.value(value: authBloc),
      ],
      child: const _InboundSheet(),
    ),
  );
}

void showInboundHistorySheet(BuildContext context) {
  final inboundBloc = context.read<InboundBloc>();

  inboundBloc.add(const OnInboundStarted());

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: inboundBloc,
      child: const _InboundHistorySheet(),
    ),
  );
}

class _InboundHistorySheet extends StatelessWidget {
  const _InboundHistorySheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: goldDeep.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      SolarIconsOutline.documentText,
                      color: goldDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt History',
                          style: AppTextStyles.bs400(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review recent inbound stock receipts',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      SolarIconsOutline.refresh,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      // context.read<InboundBloc>().add(
                      //   const OnInboundRefreshed(),
                      // );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      SolarIconsOutline.closeCircle,
                      color: colors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDims.s3),
            const Divider(height: 1),
            const Expanded(
              child: _HistoryTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboundSheet extends StatefulWidget {
  const _InboundSheet();

  @override
  State<_InboundSheet> createState() => _InboundSheetState();
}

class _InboundSheetState extends State<_InboundSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return BlocListener<InboundBloc, InboundState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == InboundSubmitStatus.success) {
          GlobalSnackBar.show(
            message: 'Stock received successfully',
            isInfo: true,
          );
          context.read<InboundBloc>().add(const OnInboundAcknowledge());
          _tabs.animateTo(1);
        } else if (state.submitStatus == InboundSubmitStatus.queued) {
          GlobalSnackBar.show(
            message: 'Queued — will sync when online',
            isWarning: true,
          );
          context.read<InboundBloc>().add(const OnInboundAcknowledge());
          _tabs.animateTo(1);
        } else if (state.submitStatus == InboundSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Failed to receive stock',
            isError: true,
          );
          context.read<InboundBloc>().add(const OnInboundAcknowledge());
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
                  top: Radius.circular(24),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: goldDeep.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            SolarIconsOutline.box,
                            color: goldDeep,
                            size: 20,
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
                                style: AppTextStyles.bs400(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Receive stock and review receipt history',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bs200(context).copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            SolarIconsOutline.closeCircle,
                            color: colors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDims.s2),
                  TabBar(
                    controller: _tabs,
                    indicatorColor: goldDeep,
                    labelColor: goldDeep,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Receive Stock'),
                      Tab(text: 'History'),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: const [
                        _ReceiveForm(),
                        _HistoryTab(),
                      ],
                    ),
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

// ── Receive Form ──────────────────────────────────────────────────────────────

class _LineItem {
  ProductData? product;
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController cost = TextEditingController();
  final TextEditingController expiry = TextEditingController();
  final TextEditingController batch = TextEditingController();

  void dispose() {
    qty.dispose();
    cost.dispose();
    expiry.dispose();
    batch.dispose();
  }
}

class _ReceiveForm extends StatefulWidget {
  const _ReceiveForm();

  @override
  State<_ReceiveForm> createState() => _ReceiveFormState();
}

class _ReceiveFormState extends State<_ReceiveForm> {
  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _vendorId;
  final List<_LineItem> _items = [_LineItem()];

  @override
  void dispose() {
    _refCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String? _shopId() {
    final shops = context.read<AuthBloc>().state.defaultBusiness?.shops;
    return (shops != null && shops.isNotEmpty) ? shops.first.id : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final shopId = _shopId();
    if (shopId == null || shopId.isEmpty) {
      GlobalSnackBar.show(
        message: 'No shop found',
        isError: true,
      );
      return;
    }
    final lineItems = _items
        .where((i) => i.product != null && i.qty.text.trim().isNotEmpty)
        .map(
          (i) => CreateInboundItemRequestDto(
            productId: i.product!.id ?? '',
            quantity: i.qty.text.trim(),
            unitCost: i.cost.text.trim().isEmpty ? null : i.cost.text.trim(),
            expiryDate:
                i.expiry.text.trim().isEmpty ? null : i.expiry.text.trim(),
            batchNumber:
                i.batch.text.trim().isEmpty ? null : i.batch.text.trim(),
          ),
        )
        .toList();

    if (lineItems.isEmpty) {
      GlobalSnackBar.show(
        message: 'Add at least one product',
        isError: true,
      );
      return;
    }
    if (_vendorId == null || _vendorId!.trim().isEmpty) {
      GlobalSnackBar.show(
        message: 'Please select a vendor',
        isError: true,
      );
      return;
    }

    context.read<InboundBloc>().add(
          OnInboundFormSubmit(
            CreateInboundRequestDto(
              shopId: shopId,
              reference: _refCtrl.text.trim(),
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              vendorId: _vendorId!,
              items: lineItems,
            ),
          ),
        );
  }

  void _pickExpiry(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _items[index].expiry.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _pickProduct(int index) async {
    final products = context.read<ProductBloc>().state.products;
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
      builder: (_) => BlocProvider.value(
        value: context.read<ProductBloc>(),
        child: _ProductPickerSheet(products: products),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _items[index].product = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return BlocBuilder<InboundBloc, InboundState>(
      buildWhen: (p, c) => p.submitStatus != c.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == InboundSubmitStatus.loading;

        return Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s4,
                    AppDims.s4,
                    AppDims.s6,
                  ),
                  children: [
                    BlocBuilder<VendorsBloc, VendorsState>(
                      buildWhen: (p, c) => p.vendors != c.vendors,
                      builder: (context, vs) {
                        if (vs.vendors.isEmpty) {
                          return TextFormField(
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Vendor *',
                              hintText: 'No vendors available',
                              prefixIcon: Icon(SolarIconsOutline.buildings),
                            ),
                            validator: (_) => 'Vendor is required',
                          );
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _vendorId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vendor *',
                            prefixIcon: Icon(SolarIconsOutline.buildings),
                          ),
                          hint: const Text('Select vendor'),
                          items: vs.vendors.map((v) {
                            return DropdownMenuItem<String>(
                              value: v.id,
                              child: Text(
                                v.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vendor is required';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => _vendorId = value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppDims.s3),

                    TextFormField(
                      controller: _refCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Reference *',
                        hintText: 'Invoice or PO number',
                        prefixIcon: Icon(SolarIconsOutline.documentText),
                      ),
                      validator: (v) {
                        return (v == null || v.trim().isEmpty)
                            ? 'Reference is required'
                            : null;
                      },
                    ),
                    const SizedBox(height: AppDims.s3),

                    TextFormField(
                      controller: _notesCtrl,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(SolarIconsOutline.notes),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppDims.s4),

                    Row(
                      children: [
                        Text(
                          'Products',
                          style: AppTextStyles.bs300(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _items.add(_LineItem()));
                          },
                          icon: const Icon(
                            SolarIconsOutline.addCircle,
                            size: 16,
                          ),
                          label: const Text('Add Row'),
                          style: TextButton.styleFrom(
                            foregroundColor: goldDeep,
                          ),
                        ),
                      ],
                    ),

                    ...List.generate(_items.length, (i) {
                      final item = _items[i];

                      return _LineItemCard(
                        key: ObjectKey(item),
                        index: i,
                        item: item,
                        canRemove: _items.length > 1,
                        onPickProduct: () {
                          FocusScope.of(context).unfocus();
                          _pickProduct(i);
                        },
                        onPickExpiry: () {
                          FocusScope.of(context).unfocus();
                          _pickExpiry(i);
                        },
                        onRemove: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            item.dispose();
                            _items.removeAt(i);
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),

              Container(
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
                      color: colors.textSecondary.withValues(alpha: 0.10),
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
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                      FocusScope.of(context).unfocus();
                      _submit();
                    },
                    icon: isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(SolarIconsOutline.box),
                    label: Text(
                      isLoading ? 'Submitting...' : 'Receive Stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldDeep,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: goldDeep.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LineItemCard extends StatelessWidget {
  final int index;
  final _LineItem item;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onPickExpiry;
  final VoidCallback onRemove;

  const _LineItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.canRemove,
    required this.onPickProduct,
    required this.onPickExpiry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: goldDeep.withValues(alpha: 0.04),
        border: Border.all(color: goldDeep.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: AppTextStyles.bs200(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: goldDeep,
                ),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(SolarIconsOutline.trashBinMinimalistic,
                      size: 18, color: colors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Product picker button
          GestureDetector(
            onTap: onPickProduct,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(SolarIconsOutline.bag5,
                      size: 18, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.product?.name ?? 'Select product...',
                      style: TextStyle(
                        color: item.product != null
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(SolarIconsOutline.altArrowDown,
                      size: 16, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.qty,
                  decoration: const InputDecoration(
                    labelText: 'Qty *',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.cost,
                  decoration: const InputDecoration(
                    labelText: 'Cost',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onPickExpiry,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: item.expiry,
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'YYYY-MM-DD',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: Icon(SolarIconsOutline.calendar,
                            size: 18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.batch,
                  decoration: const InputDecoration(
                    labelText: 'Batch #',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Product Picker ────────────────────────────────────────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  final List<ProductData> products;
  const _ProductPickerSheet({required this.products});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
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
    if (widget.products.length <= 80) return widget.products;
    return widget.products.take(80).toList();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filtered = _initialVisibleProducts());
      return;
    }

    final results = <ProductData>[];

    for (final product in widget.products) {
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Product',
                          style: AppTextStyles.bs400(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          SolarIconsOutline.closeCircle,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name, SKU, or barcode',
                      prefixIcon: Icon(
                        SolarIconsOutline.magnifier,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
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
                    onChanged: _onSearchChanged,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s2,
                    AppDims.s4,
                    AppDims.s1,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _searchCtrl.text.trim().isEmpty
                            ? 'Showing ${_filtered.length} products'
                            : '${_filtered.length} results',
                        style: AppTextStyles.bs100(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (widget.products.length > 80)
                        Text(
                          'Search to find more',
                          style: AppTextStyles.bs100(context).copyWith(
                            color: goldDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                      : ListView.separated(
                    controller: scrollController,
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s4,
                      vertical: AppDims.s2,
                    ),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = _filtered[i];

                      return Material(
                        color: colors.textSecondary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context, p);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: goldDeep.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    SolarIconsOutline.bag5,
                                    color: goldDeep,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name ?? 'Unnamed product',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bs300(context)
                                            .copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if ((p.sku ?? '').isNotEmpty)
                                            'SKU: ${p.sku}',
                                          if ((p.barcode ?? '').isNotEmpty)
                                            'Barcode: ${p.barcode}',
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bs100(context)
                                            .copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  SolarIconsOutline.altArrowRight,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
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
// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<InboundBloc, InboundState>(
      builder: (context, state) {
        if (state.status == InboundStatus.loading && state.history.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(SolarIconsOutline.boxMinimalistic,
                    size: 48,
                    color: colors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'No inbound transactions yet',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                ),
              ],
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification &&
                n.metrics.extentAfter < 200 &&
                state.hasMorePages) {
              context.read<InboundBloc>().add(const OnInboundLoadMore());
            }
            return false;
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: AppDims.s2),
            itemCount: state.history.length +
                (state.status == InboundStatus.loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == state.history.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _HistoryTile(tx: state.history[i]);
            },
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final InboundTransactionData tx;
  const _HistoryTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final date = tx.createdAt != null
        ? tx.createdAt!.substring(0, 10)
        : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        tx.reference ?? '—',
        style: AppTextStyles.bs300(context).copyWith(
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        [
          if (tx.vendorName != null) tx.vendorName!,
          if (date.isNotEmpty) date,
        ].join(' · '),
        style: AppTextStyles.bs200(context)
            .copyWith(color: colors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: goldDeep.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${tx.itemCount} item${tx.itemCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: goldDeep,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (tx.totalQuantity != null)
            Text(
              'Qty: ${tx.totalQuantity}',
              style: AppTextStyles.bs100(context)
                  .copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}
