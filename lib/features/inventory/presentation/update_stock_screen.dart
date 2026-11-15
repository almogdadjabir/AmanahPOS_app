import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/config/providers/feature_bloc_providers.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_row.dart';
import 'package:amana_pos/features/users/data/models/movement_type.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

enum UpdateStockMode { add, remove, count, move }

/// Opens the one Update stock screen for [product]. Uses the caller's
/// [InventoryBloc] when there is one (so the caller refreshes), otherwise a
/// fresh inventory scope.
Future<void> openUpdateStock(
  BuildContext context, {
  required ProductData product,
  UpdateStockMode mode = UpdateStockMode.add,
}) {
  final hasInventory =
      context.findAncestorWidgetOfExactType<BlocProvider<InventoryBloc>>() !=
      null;

  if (!hasInventory) {
    return Navigator.of(context).push(
      motionPageRoute(
        FeatureBlocProviders.inventory(
          child: UpdateStockScreen(product: product, mode: mode),
        ),
      ),
    );
  }

  final inventoryBloc = context.read<InventoryBloc>();
  return Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(
        value: inventoryBloc,
        child: UpdateStockScreen(product: product, mode: mode),
      ),
    ),
  );
}

class UpdateStockScreen extends StatefulWidget {
  final ProductData product;
  final UpdateStockMode mode;

  const UpdateStockScreen({
    super.key,
    required this.product,
    this.mode = UpdateStockMode.add,
  });

  @override
  State<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends State<UpdateStockScreen> {
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _qtyFocus = FocusNode();

  late UpdateStockMode _mode;
  late final List<ShopData> _shops;
  String? _shopId;
  String? _toShopId;
  DateTime? _expiry;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _shops = _loadShops();

    final inventory = context.read<InventoryBloc>();
    if (inventory.state.status == InventoryStatus.initial &&
        inventory.state.stockList.isEmpty) {
      inventory.add(const OnInventoryInitial());
    }

    _mode = widget.mode;
    if (_mode == UpdateStockMode.move && _shops.length < 2) {
      _mode = UpdateStockMode.add;
    }

    _shopId = _defaultShop(inventory.state);
    _fixToShop();
    _resetQuantity();
    _qtyCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  // ---- data --------------------------------------------------------------

  List<ShopData> _loadShops() {
    final businesses = context.read<BusinessBloc>().state.businessList;
    if (businesses == null || businesses.isEmpty) return const [];
    return (businesses.first.shops ?? const [])
        .where((s) => (s.id?.trim().isNotEmpty ?? false) && s.isActive != false)
        .toList(growable: false);
  }

  String? _defaultShop(InventoryState state) {
    if (_shops.isEmpty) return null;
    final productId = widget.product.id;
    for (final row in state.stockList) {
      if (row.product == productId && _shops.any((s) => s.id == row.shop)) {
        return row.shop;
      }
    }
    return _shops.first.id;
  }

  void _fixToShop() {
    if (_shops.length < 2) {
      _toShopId = null;
      return;
    }
    if (_toShopId == null || _toShopId == _shopId) {
      _toShopId = _shops.firstWhere((s) => s.id != _shopId).id;
    }
  }

  double _current(InventoryState state, String? shopId) {
    final productId = widget.product.id;
    var found = false;
    var sum = 0.0;
    for (final row in state.stockList) {
      if (row.product == productId && row.shop == shopId) {
        found = true;
        sum += row.qty;
      }
    }
    if (found) return sum;
    // No row loaded: a single-shop business holds the whole product total.
    if (_shops.length <= 1) return widget.product.stockLevel ?? 0;
    return 0;
  }

  String _shopName(String? id) {
    for (final s in _shops) {
      if (s.id == id) return s.name ?? context.tr.shop;
    }
    return context.tr.shop;
  }

  // ---- quantity ----------------------------------------------------------

  double? get _qty {
    final raw = _qtyCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  void _resetQuantity() {
    final state = context.read<InventoryBloc>().state;
    final value = _mode == UpdateStockMode.count
        ? _current(state, _shopId)
        : 1.0;
    _setQty(value);
  }

  void _setQty(double v) {
    final text = formatQty(v < 0 ? 0 : v);
    _qtyCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _step(int delta) {
    HapticFeedback.selectionClick();
    final current = _qty ?? 0;
    final next = (current + delta).clamp(0, 1e9).toDouble();
    _setQty(next);
  }

  // ---- validation --------------------------------------------------------

  ({double after, String? error, bool valid}) _evaluate(InventoryState state) {
    final q = _qty;
    final cur = _current(state, _shopId);
    if (q == null) return (after: cur, error: null, valid: false);

    switch (_mode) {
      case UpdateStockMode.add:
        return (after: cur + q, error: null, valid: q > 0);
      case UpdateStockMode.remove:
        final enough = q <= cur;
        return (
          after: cur - q,
          error: enough ? null : context.tr.usNotEnough,
          valid: q > 0 && enough,
        );
      case UpdateStockMode.count:
        return (after: q, error: null, valid: q >= 0);
      case UpdateStockMode.move:
        final enough = q <= cur;
        final same = _shopId == _toShopId;
        return (
          after: cur - q,
          error: same
              ? context.tr.usPickDifferentShop
              : (enough ? null : context.tr.usNotEnough),
          valid: q > 0 && enough && !same && _toShopId != null,
        );
    }
  }

  // ---- actions -----------------------------------------------------------

  Future<void> _pickShop({required bool target}) async {
    if (_shops.length < 2) return;
    final selected = target ? _toShopId : _shopId;

    final picked = await showAdaptivePanel<String>(
      context,
      showDragHandle: false,
      builder: (sheetContext) => AppSheet(
        title: target ? sheetContext.tr.usTo : sheetContext.tr.shop,
        maxHeightFactor: 0.7,
        child: _ShopList(shops: _shops, selectedId: selected),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (target) {
        _toShopId = picked;
      } else {
        _shopId = picked;
        _fixToShop();
        if (_mode == UpdateStockMode.count) _resetQuantity();
      }
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null && mounted) setState(() => _expiry = picked);
  }

  void _setMode(UpdateStockMode mode) {
    if (mode == _mode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _fixToShop();
      _resetQuantity();
    });
  }

  void _submit() {
    final state = context.read<InventoryBloc>().state;
    final eval = _evaluate(state);
    final q = _qty;
    final shopId = _shopId;
    final productId = widget.product.id;
    if (!eval.valid || q == null || shopId == null || productId == null) {
      return;
    }

    HapticFeedback.mediumImpact();
    final bloc = context.read<InventoryBloc>();
    final note = _noteCtrl.text.trim();
    final qtyText = formatQty(q);

    setState(() => _submitting = true);

    switch (_mode) {
      case UpdateStockMode.add:
        bloc.add(
          OnAddStock(
            productId: productId,
            shopId: shopId,
            quantity: qtyText,
            movementType: MovementType.in_,
            reference: note.isEmpty ? null : note,
            expiryDate: _expiry == null
                ? null
                : DateFormat('yyyy-MM-dd', 'en').format(_expiry!),
          ),
        );
      case UpdateStockMode.remove:
      case UpdateStockMode.count:
        bloc.add(
          OnAdjustStock(
            productId: productId,
            shopId: shopId,
            newQuantity: formatQty(eval.after),
            notes: note.isEmpty ? null : note,
          ),
        );
      case UpdateStockMode.move:
        bloc.add(
          OnTransferStock(
            productId: productId,
            fromShopId: shopId,
            toShopId: _toShopId!,
            quantity: qtyText,
          ),
        );
    }
  }

  void _onInventory(BuildContext context, InventoryState state) {
    if (!_submitting) return;

    final inventory = context.read<InventoryBloc>();

    if (state.submitStatus == InventorySubmitStatus.success ||
        state.submitStatus == InventorySubmitStatus.queued) {
      _submitting = false;
      final productBloc = context.read<ProductBloc>();
      final message = context.tr.usSaved;
      if (!inventory.isClosed) {
        inventory
          ..add(const OnAcknowledgeInventorySubmit())
          ..add(const OnInventoryInitial());
      }
      productBloc.add(const OnProductInitial(force: true));
      Navigator.of(context).pop();
      GlobalSnackBar.show(message: message, isInfo: true);
      return;
    }

    if (state.submitStatus == InventorySubmitStatus.failure) {
      setState(() => _submitting = false);
      GlobalSnackBar.show(
        message: state.submitError ?? context.tr.somethingWentWrong,
        isError: true,
        isAutoDismiss: false,
      );
      inventory.add(const OnAcknowledgeInventorySubmit());
    }
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;

    return BlocListener<InventoryBloc, InventoryState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: _onInventory,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                _TopBar(title: tr.pcUpdateStock),
                Expanded(
                  child: BlocBuilder<InventoryBloc, InventoryState>(
                    buildWhen: (p, c) =>
                        p.stockList != c.stockList || p.status != c.status,
                    builder: (context, state) => _content(context, state),
                  ),
                ),
                BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    final eval = _evaluate(state);
                    final q = _qty ?? 0;
                    final qtyText = formatQty(q);
                    final label = switch (_mode) {
                      UpdateStockMode.add => tr.usSaveAdd(qtyText),
                      UpdateStockMode.remove => tr.usSaveRemove(qtyText),
                      UpdateStockMode.count => tr.usSaveCount(qtyText),
                      UpdateStockMode.move => tr.usSaveMove(qtyText),
                    };
                    final loading =
                        state.submitStatus == InventorySubmitStatus.loading;

                    return Container(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        10,
                        AppDims.s4,
                        keyboard
                            ? 10
                            : MediaQuery.viewPaddingOf(context).bottom + 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background.withValues(alpha: 0.92),
                        border: Border(
                          top: BorderSide(color: colors.border, width: 0.5),
                        ),
                      ),
                      child: AppButton.wide(
                        label: label,
                        isLoading: loading,
                        onPressed: eval.valid && !loading ? _submit : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, InventoryState state) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;
    final eval = _evaluate(state);
    final cur = _current(state, _shopId);
    final unit = (widget.product.unit?.trim().isNotEmpty ?? false)
        ? widget.product.unit!.trim()
        : tr.pcUnitsShort;

    final modes = <AppSegment<UpdateStockMode>>[
      AppSegment(value: UpdateStockMode.add, label: tr.usAdd),
      AppSegment(value: UpdateStockMode.remove, label: tr.usRemove),
      AppSegment(value: UpdateStockMode.count, label: tr.usCount),
      if (_shops.length > 1)
        AppSegment(value: UpdateStockMode.move, label: tr.usMove),
    ];

    final hint = switch (_mode) {
      UpdateStockMode.add => tr.usHintAdd,
      UpdateStockMode.remove => tr.usHintRemove,
      UpdateStockMode.count => tr.usHintCount,
      UpdateStockMode.move => tr.usHintMove,
    };

    final name = productDisplayName(context, widget.product);

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s2,
        AppDims.s4,
        24,
      ),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: 12,
            ),
            child: Row(
              children: [
                ProductThumb(product: widget.product, size: 40, radius: 10),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_shopName(_shopId)} · ${formatQty(cur)} $unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall!.copyWith(
                          fontSize: 13,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDims.s4),
        AppSegmented<UpdateStockMode>(
          segments: modes,
          selected: _mode,
          onChanged: _setMode,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: colors.textHint,
            ),
          ),
        ),
        _Stepper(
          controller: _qtyCtrl,
          focusNode: _qtyFocus,
          onMinus: () => _step(-1),
          onPlus: () => _step(1),
        ),
        _AfterLine(
          label: tr.usAfter,
          value: '${formatQty(eval.after)} $unit',
          error: eval.error,
        ),
        const SizedBox(height: AppDims.s4),
        if (_mode == UpdateStockMode.move)
          AppFormGroup(
            children: [
              AppFormRow(
                label: tr.usFrom,
                chevron: _shops.length > 1,
                onTap: () => _pickShop(target: false),
                child: AppRowValue(_shopName(_shopId)),
              ),
              AppFormRow(
                label: tr.usTo,
                chevron: _shops.length > 1,
                onTap: () => _pickShop(target: true),
                child: AppRowValue(_shopName(_toShopId)),
              ),
            ],
          )
        else
          AppFormGroup(
            children: [
              AppFormRow(
                label: tr.shop,
                chevron: _shops.length > 1,
                onTap: _shops.length > 1
                    ? () => _pickShop(target: false)
                    : null,
                child: AppRowValue(_shopName(_shopId)),
              ),
              if (_mode == UpdateStockMode.add)
                AppFormRow(
                  label: tr.usExpiryDate,
                  onTap: _pickExpiry,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppRowValue(
                          _expiry == null
                              ? tr.optional
                              : DateFormat.yMMMd(
                                  Localizations.localeOf(context).toString(),
                                ).format(_expiry!),
                          placeholder: _expiry == null,
                        ),
                      ),
                      Icon(
                        PhosphorIconsRegular.calendarBlank,
                        size: 20,
                        color: colors.textHint,
                      ),
                    ],
                  ),
                ),
              AppFormRow(
                label: tr.usNote,
                child: AppRowTextField(
                  controller: _noteCtrl,
                  hint: tr.optional,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Pressable(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        child: Text(
                          context.tr.cancel,
                          style: TextStyle(fontSize: 17, color: colors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 88),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _Stepper({
    required this.controller,
    required this.focusNode,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundButton(
            icon: PhosphorIconsRegular.minus,
            background: colors.surfaceSoft,
            foreground: colors.textPrimary,
            onTap: onMinus,
          ),
          const SizedBox(width: 22),
          SizedBox(
            width: 140,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              cursorColor: colors.primary,
              style: TextStyle(
                fontSize: 56,
                height: 60 / 56,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.7,
                color: colors.textPrimary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 22),
          _RoundButton(
            icon: PhosphorIconsRegular.plus,
            background: colors.primaryContainer,
            foreground: colors.primary,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 24, color: foreground),
      ),
    );
  }
}

class _AfterLine extends StatelessWidget {
  final String label;
  final String value;
  final String? error;

  const _AfterLine({
    required this.label,
    required this.value,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (error != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.warningCircle,
            size: 16,
            color: colors.danger,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              error!,
              style: TextStyle(fontSize: 15, color: colors.danger),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: colors.textSecondary),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ShopList extends StatelessWidget {
  final List<ShopData> shops;
  final String? selectedId;

  const _ShopList({required this.shops, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < shops.length; i++) ...[
              Pressable(
                scale: 1,
                onTap: () => Navigator.of(context).pop(shops[i].id),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 54),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shops[i].name ?? context.tr.shop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (shops[i].id == selectedId)
                          Icon(
                            PhosphorIconsRegular.check,
                            size: 22,
                            color: colors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < shops.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4,
                  color: colors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
