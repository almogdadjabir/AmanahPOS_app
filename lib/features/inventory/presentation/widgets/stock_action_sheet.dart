import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/users/data/models/movement_type.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _Tab { add, adjust, transfer }

void showStockActionSheet(
    BuildContext context, {
      required StockData stock,
      required List<StockData> allStock,
    }) {
  final bloc = context.read<InventoryBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _StockActionSheet(stock: stock, allStock: allStock),
    ),
  );
}

class _StockActionSheet extends StatefulWidget {
  final StockData stock;
  final List<StockData> allStock;
  const _StockActionSheet(
      {required this.stock, required this.allStock});

  @override
  State<_StockActionSheet> createState() => _StockActionSheetState();
}

class _StockActionSheetState extends State<_StockActionSheet> {
  _Tab _tab = _Tab.add;
  MovementType _movementType = MovementType.in_;

  // ── Add stock ─────────────────────────────────────────────────────────
  final _addFormKey   = GlobalKey<FormState>();
  final _addQtyCtrl   = TextEditingController();
  final _addRefCtrl   = TextEditingController();
  final _addQtyFocus  = FocusNode();
  final _addRefFocus  = FocusNode();

  // ── Adjust stock ──────────────────────────────────────────────────────
  final _adjFormKey   = GlobalKey<FormState>();
  final _adjQtyCtrl   = TextEditingController();
  final _adjNoteCtrl  = TextEditingController();
  final _adjQtyFocus  = FocusNode();
  final _adjNoteFocus = FocusNode();

  // ── Transfer ──────────────────────────────────────────────────────────
  final _trFormKey    = GlobalKey<FormState>();
  final _trQtyCtrl    = TextEditingController();
  final _trQtyFocus   = FocusNode();
  StockData? _toShopStock;

  @override
  void initState() {
    super.initState();
    // Pre-fill adjust with current qty
    _adjQtyCtrl.text = widget.stock.qty % 1 == 0
        ? widget.stock.qty.toInt().toString()
        : widget.stock.qty.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _addQtyCtrl.dispose(); _addRefCtrl.dispose();
    _adjQtyCtrl.dispose(); _adjNoteCtrl.dispose();
    _trQtyCtrl.dispose();
    _addQtyFocus.dispose(); _addRefFocus.dispose();
    _adjQtyFocus.dispose(); _adjNoteFocus.dispose();
    _trQtyFocus.dispose();
    super.dispose();
  }

  // ── Available shops to transfer TO (same product, different shop) ─────
  List<StockData> get _otherShops => widget.allStock
      .where((s) =>
  s.product == widget.stock.product &&
      s.shop    != widget.stock.shop)
      .toList();

  void _submitAdd() {
    if (!_addFormKey.currentState!.validate()) return;
    context.read<InventoryBloc>().add(OnAddStock(
      productId: widget.stock.product!,
      shopId:    widget.stock.shop!,
      quantity:  _addQtyCtrl.text.trim(),
      movementType: _movementType,
      reference: _addRefCtrl.text.trim().isEmpty
          ? null
          : _addRefCtrl.text.trim(),
    ));
  }

  void _submitAdjust() {
    if (!_adjFormKey.currentState!.validate()) return;
    context.read<InventoryBloc>().add(OnAdjustStock(
      productId:   widget.stock.product!,
      shopId:      widget.stock.shop!,
      newQuantity: _adjQtyCtrl.text.trim(),
      notes:       _adjNoteCtrl.text.trim().isEmpty
          ? null
          : _adjNoteCtrl.text.trim(),
    ));
  }

  void _submitTransfer() {
    if (!_trFormKey.currentState!.validate()) return;
    if (_toShopStock == null) {
      GlobalSnackBar.show(
        message: 'Please select a destination shop',
        isError: true,
      );
      return;
    }
    context.read<InventoryBloc>().add(OnTransferStock(
      productId:  widget.stock.product!,
      fromShopId: widget.stock.shop!,
      toShopId:   _toShopStock!.shop!,
      quantity:   _trQtyCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == InventorySubmitStatus.success) {
          Navigator.of(context).pop();
          // Trigger refetch
          context.read<InventoryBloc>().add(const OnInventoryInitial());
          GlobalSnackBar.show(
            message: switch (_tab) {
              _Tab.add      => 'Stock added successfully',
              _Tab.adjust   => 'Stock adjusted successfully',
              _Tab.transfer => 'Stock transferred successfully',
            },
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
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDims.rXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────
              const SizedBox(height: AppDims.s3),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stock.productName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs600(context).copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.stock.shopName ?? '—',
                            style: AppTextStyles.bs300(context).copyWith(
                              color: context.appColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Current qty badge ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDims.s3, vertical: AppDims.s1),
                      decoration: BoxDecoration(
                        color: context.appColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppDims.rSm),
                      ),
                      child: Text(
                        'Qty: ${widget.stock.qty % 1 == 0 ? widget.stock.qty.toInt() : widget.stock.qty.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'NunitoSans', fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDims.s2),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 20,
                            color: context.appColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab selector ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppDims.s4),
                child: _TabSelector(
                  selected: _tab,
                  onSelect: (t) => setState(() => _tab = t),
                ),
              ),

              // ── Tab content ───────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDims.s4, 0, AppDims.s4, AppDims.s4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: switch (_tab) {
                      _Tab.add => _AddStockForm(
                        key:               const ValueKey('add'),
                        formKey:           _addFormKey,
                        qtyCtrl:           _addQtyCtrl,
                        refCtrl:           _addRefCtrl,
                        qtyFocus:          _addQtyFocus,
                        refFocus:          _addRefFocus,
                        selectedMovement:  _movementType,          // ← new
                        onMovementChanged: (t) => setState(() => _movementType = t), // ← new
                        onSubmit:          _submitAdd,
                      ),
                      _Tab.adjust   => _AdjustStockForm(
                        key: const ValueKey('adj'),
                        formKey:   _adjFormKey,
                        qtyCtrl:   _adjQtyCtrl,
                        noteCtrl:  _adjNoteCtrl,
                        qtyFocus:  _adjQtyFocus,
                        noteFocus: _adjNoteFocus,
                        onSubmit:  _submitAdjust,
                      ),
                      _Tab.transfer => _TransferStockForm(
                        key: const ValueKey('tr'),
                        formKey:      _trFormKey,
                        qtyCtrl:      _trQtyCtrl,
                        qtyFocus:     _trQtyFocus,
                        otherShops:   _otherShops,
                        selectedShop: _toShopStock,
                        onShopSelect: (s) =>
                            setState(() => _toShopStock = s),
                        onSubmit:     _submitTransfer,
                      ),
                    },
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

// ─── Tab selector ─────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  final _Tab selected;
  final ValueChanged<_Tab> onSelect;

  const _TabSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          _TabChip(
            label: 'Add In',
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF16A34A),
            selected: selected == _Tab.add,
            onTap: () => onSelect(_Tab.add),
          ),
          _TabChip(
            label: 'Adjust',
            icon: Icons.tune_rounded,
            color: const Color(0xFF0EA5E9),
            selected: selected == _Tab.adjust,
            onTap: () => onSelect(_Tab.adjust),
          ),
          _TabChip(
            label: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF8B5CF6),
            selected: selected == _Tab.transfer,
            onTap: () => onSelect(_Tab.transfer),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppDims.s2),
          decoration: BoxDecoration(
            color: selected
                ? context.appColors.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rSm),
            border: selected
                ? Border.all(color: context.appColors.border)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected
                      ? color
                      : context.appColors.textHint),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? color
                      : context.appColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add stock form ───────────────────────────────────────────────────────────
MovementType _movementType = MovementType.in_;

class _AddStockForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController qtyCtrl;
  final TextEditingController refCtrl;
  final FocusNode qtyFocus;
  final FocusNode refFocus;
  final MovementType selectedMovement;            // ← new
  final ValueChanged<MovementType> onMovementChanged; // ← new
  final VoidCallback onSubmit;

  const _AddStockForm({
    super.key,
    required this.formKey,
    required this.qtyCtrl,
    required this.refCtrl,
    required this.qtyFocus,
    required this.refFocus,
    required this.selectedMovement,
    required this.onMovementChanged,
    required this.onSubmit,
  });

  // Only the types a user can manually select — system types excluded
  static const _selectable = [
    MovementType.in_,
    MovementType.out,
    MovementType.opening,
    MovementType.return_,
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Movement type ────────────────────────────────────────────
          FieldLabel(label: 'Movement Type', required: true),
          const SizedBox(height: AppDims.s2),
          Wrap(
            spacing: AppDims.s2,
            runSpacing: AppDims.s2,
            children: _selectable.map((type) {
              final isSelected = selectedMovement == type;
              final color = switch (type) {
                MovementType.in_     => const Color(0xFF16A34A),
                MovementType.out     => const Color(0xFFDC2626),
                MovementType.opening => const Color(0xFF0EA5E9),
                MovementType.return_ => const Color(0xFFEA580C),
                _                    => const Color(0xFF0D9488),
              };

              return GestureDetector(
                onTap: () => onMovementChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s3, vertical: AppDims.s2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.10)
                        : context.appColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: isSelected ? color : context.appColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      fontFamily: 'NunitoSans', fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? color
                          : context.appColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDims.s3),

          // ── Quantity ─────────────────────────────────────────────────
          FieldLabel(label: 'Quantity', required: true),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller:  qtyCtrl,
            focusNode:   qtyFocus,
            nextFocus:   refFocus,
            hint:         '50',
            prefixIcon:   Icons.add_circle_outline_rounded,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Quantity is required';
              if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
              if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
          const SizedBox(height: AppDims.s3),

          // ── Reference ─────────────────────────────────────────────────
          FieldLabel(label: 'Reference'),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller:     refCtrl,
            focusNode:      refFocus,
            hint:            'PO-001',
            prefixIcon:      Icons.tag_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted:     (_) => onSubmit(),
          ),
          const SizedBox(height: AppDims.s5),
          _SubmitButton(
            label:    'Confirm Movement',
            color:    switch (selectedMovement) {
              MovementType.in_     => const Color(0xFF16A34A),
              MovementType.out     => const Color(0xFFDC2626),
              MovementType.opening => const Color(0xFF0EA5E9),
              MovementType.return_ => const Color(0xFFEA580C),
              _                    => const Color(0xFF0D9488),
            },
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Adjust stock form ────────────────────────────────────────────────────────

class _AdjustStockForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController qtyCtrl;
  final TextEditingController noteCtrl;
  final FocusNode qtyFocus;
  final FocusNode noteFocus;
  final VoidCallback onSubmit;

  const _AdjustStockForm({
    super.key,
    required this.formKey,
    required this.qtyCtrl,
    required this.noteCtrl,
    required this.qtyFocus,
    required this.noteFocus,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info banner ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDims.s3),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(
                  color: const Color(0xFF0EA5E9).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFF0EA5E9)),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: Text(
                    'This sets the exact stock quantity, overriding the current value.',
                    style: AppTextStyles.bs200(context).copyWith(
                      color: const Color(0xFF0EA5E9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'New Quantity', required: true),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller:  qtyCtrl,
            focusNode:   qtyFocus,
            nextFocus:   noteFocus,
            hint:         '45',
            prefixIcon:   Icons.tune_rounded,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Quantity is required';
              if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
              if ((double.tryParse(v.trim()) ?? -1) < 0) return 'Cannot be negative';
              return null;
            },
          ),
          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'Notes'),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller:      noteCtrl,
            focusNode:       noteFocus,
            hint:             'Stock count correction',
            prefixIcon:       Icons.notes_rounded,
            maxLines:         2,
            textInputAction:  TextInputAction.done,
            onSubmitted:      (_) => onSubmit(),
          ),
          const SizedBox(height: AppDims.s5),
          _SubmitButton(
            label: 'Adjust Stock',
            color: const Color(0xFF0EA5E9),
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Transfer stock form ──────────────────────────────────────────────────────

class _TransferStockForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController qtyCtrl;
  final FocusNode qtyFocus;
  final List<StockData> otherShops;
  final StockData? selectedShop;
  final ValueChanged<StockData> onShopSelect;
  final VoidCallback onSubmit;

  const _TransferStockForm({
    super.key,
    required this.formKey,
    required this.qtyCtrl,
    required this.qtyFocus,
    required this.otherShops,
    required this.selectedShop,
    required this.onShopSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── To shop picker ───────────────────────────────────────────
          FieldLabel(label: 'Transfer To', required: true),
          const SizedBox(height: AppDims.s1),
          if (otherShops.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDims.s3),
              decoration: BoxDecoration(
                color: context.appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rMd),
                border: Border.all(color: context.appColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 16, color: context.appColors.textHint),
                  const SizedBox(width: AppDims.s2),
                  Text(
                    'No other shops available for this product',
                    style: AppTextStyles.bs300(context).copyWith(
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ),
            )
          else
            ...otherShops.map((shop) {
              final isSelected = selectedShop?.shop == shop.shop;
              return GestureDetector(
                onTap: () => onShopSelect(shop),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: AppDims.s2),
                  padding: const EdgeInsets.all(AppDims.s3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5CF6).withOpacity(0.08)
                        : context.appColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : context.appColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 16,
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : context.appColors.textHint),
                      const SizedBox(width: AppDims.s2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.shopName ?? '—',
                              style: AppTextStyles.bs400(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF8B5CF6)
                                    : context.appColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Current: ${shop.qty % 1 == 0 ? shop.qty.toInt() : shop.qty.toStringAsFixed(2)}',
                              style: AppTextStyles.bs200(context).copyWith(
                                color: context.appColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            size: 18,
                            color: const Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: AppDims.s3),

          FieldLabel(label: 'Quantity to Transfer', required: true),
          const SizedBox(height: AppDims.s1),
          AppFormField(
            controller:  qtyCtrl,
            focusNode:   qtyFocus,
            hint:         '10',
            prefixIcon:   Icons.swap_horiz_rounded,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted:  (_) => onSubmit(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Quantity is required';
              if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
              if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
          const SizedBox(height: AppDims.s5),
          _SubmitButton(
            label: 'Transfer Stock',
            color: const Color(0xFF8B5CF6),
            onSubmit: otherShops.isEmpty ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Shared submit button ─────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onSubmit;

  const _SubmitButton({
    required this.label,
    required this.color,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      builder: (context, state) {
        final isLoading =
            state.submitStatus == InventorySubmitStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isLoading || onSubmit == null ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: context.appColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white,
              ),
            )
                : Text(
              label,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}