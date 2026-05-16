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
    return BlocListener<InboundBloc, InboundState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == InboundSubmitStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock received successfully'),
              backgroundColor: Color(0xFF059669),
            ),
          );
          context.read<InboundBloc>().add(const OnInboundAcknowledge());
          _tabs.animateTo(1);
        } else if (state.submitStatus == InboundSubmitStatus.queued) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Queued — will sync when online'),
              backgroundColor: goldDeep,
            ),
          );
          context.read<InboundBloc>().add(const OnInboundAcknowledge());
          _tabs.animateTo(1);
        } else if (state.submitStatus == InboundSubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submitError ?? 'Failed to receive stock'),
              backgroundColor: Colors.red,
            ),
          );
          context.read<InboundBloc>().add(const OnInboundAcknowledge());
        }
      },
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.95,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDims.s4),
                child: Row(
                  children: [
                    Text(
                      'Inbound Receiving',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(SolarIconsOutline.closeCircle,
                          color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                indicatorColor: goldDeep,
                labelColor: goldDeep,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shop found')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product')),
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
              vendorId: _vendorId,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products loaded')),
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
    return BlocBuilder<InboundBloc, InboundState>(
      buildWhen: (p, c) => p.submitStatus != c.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == InboundSubmitStatus.loading;
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDims.s4),
            children: [
              // Vendor dropdown
              BlocBuilder<VendorsBloc, VendorsState>(
                buildWhen: (p, c) => p.vendors != c.vendors,
                builder: (context, vs) {
                  if (vs.vendors.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String>(
                    initialValue: _vendorId,
                    decoration: const InputDecoration(
                      labelText: 'Vendor (optional)',
                      prefixIcon: Icon(SolarIconsOutline.buildings),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...vs.vendors.map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => _vendorId = v,
                  );
                },
              ),
              const SizedBox(height: AppDims.s3),
              // Reference
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference *',
                  hintText: 'Invoice or PO number',
                  prefixIcon: Icon(SolarIconsOutline.documentText),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Reference is required' : null,
              ),
              const SizedBox(height: AppDims.s2),
              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(SolarIconsOutline.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppDims.s4),
              // Line items header
              Row(
                children: [
                  Text(
                    'Products',
                    style: AppTextStyles.bs300(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _items.add(_LineItem())),
                    icon: const Icon(SolarIconsOutline.addCircle, size: 16),
                    label: const Text('Add Row'),
                    style: TextButton.styleFrom(foregroundColor: goldDeep),
                  ),
                ],
              ),
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                return _LineItemCard(
                  key: ValueKey(i),
                  index: i,
                  item: item,
                  canRemove: _items.length > 1,
                  onPickProduct: () => _pickProduct(i),
                  onPickExpiry: () => _pickExpiry(i),
                  onRemove: () => setState(() {
                    item.dispose();
                    _items.removeAt(i);
                  }),
                );
              }),
              const SizedBox(height: AppDims.s4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(SolarIconsOutline.box),
                  label: Text(
                    isLoading ? 'Submitting...' : 'Receive Stock',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldDeep,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: goldDeep.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s4),
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
  String _query = '';

  List<ProductData> get _filtered {
    if (_query.isEmpty) return widget.products;
    final q = _query.toLowerCase();
    return widget.products
        .where((p) =>
            (p.name ?? '').toLowerCase().contains(q) ||
            (p.sku ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
              const SizedBox(height: 12),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDims.s4),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(SolarIconsOutline.magnifier,
                        color: colors.textSecondary, size: 20),
                    filled: true,
                    fillColor:
                        colors.textSecondary.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s4, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _filtered[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        p.name ?? '',
                        style: AppTextStyles.bs300(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: p.sku != null
                          ? Text(
                              p.sku!,
                              style: AppTextStyles.bs200(context)
                                  .copyWith(color: colors.textSecondary),
                            )
                          : null,
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
