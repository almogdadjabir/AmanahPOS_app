import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

import '../data/stock_count_reader.dart';

class _Row {
  _Row(this.product, String counted)
    : ctrl = TextEditingController(text: counted);

  final CountProduct product;
  final TextEditingController ctrl;

  /// Null = not counted yet. [invalid] = typed something unusable.
  BigInt? counted;
  bool invalid = false;

  void parse() {
    final t = normalizeAmountInput(ctrl.text).trim();
    invalid = false;
    counted = null;
    if (t.isEmpty) return;
    try {
      final v = Decimal3.parse(t);
      if (v.isNegative) {
        invalid = true;
      } else {
        counted = v;
      }
    } on FormatException {
      invalid = true;
    }
  }

  BigInt? get diff => counted == null ? null : counted! - product.system;
}

/// Count what is on the shelf; the app works out the differences. Nothing is
/// written until Apply, then every difference is one stock adjustment, all
/// together or none. No draft: leaving asks first.
class StockCountScreen extends StatefulWidget {
  const StockCountScreen({
    super.key,
    required this.shopId,
    this.reader,
    this.service,
  });

  final String shopId;
  final StockCountReader? reader;
  final StockService? service;

  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  final _search = TextEditingController();
  final _rows = <_Row>[];
  List<CountProduct> _matches = const [];
  bool _saving = false;
  String? _message;

  StockCountReader get _reader => widget.reader ?? getIt<StockCountReader>();
  StockService get _service => widget.service ?? getIt<StockService>();

  @override
  void dispose() {
    _search.dispose();
    for (final r in _rows) {
      r.ctrl.dispose();
    }
    super.dispose();
  }

  bool get _dirty => _rows.any((r) => r.counted != null || r.invalid);
  bool get _anyInvalid => _rows.any((r) => r.invalid);
  List<_Row> get _differing =>
      _rows.where((r) => r.diff != null && r.diff != BigInt.zero).toList();

  /// Adds the product (counted 1) or, when already listed, one more.
  void _addOne(CountProduct p) {
    final i = _rows.indexWhere((r) => r.product.id == p.id);
    setState(() {
      _message = null;
      if (i == -1) {
        _rows.add(_Row(p, '1')..parse());
      } else {
        final r = _rows[i];
        final next = (r.counted ?? BigInt.zero) + BigInt.from(1000);
        r.ctrl.text = Decimal3.format(next);
        r.parse();
      }
      _search.clear();
      _matches = const [];
    });
  }

  Future<void> _onQuery(String q) async {
    final found = await _reader.search(q, widget.shopId);
    if (!mounted || q != _search.text) return;
    setState(() => _matches = found);
  }

  Future<void> _onSubmit(String q) async {
    final tr = context.tr;
    final code = q.trim();
    if (code.isEmpty) return;
    final byCode = await _reader.byCode(code, widget.shopId);
    if (!mounted) return;
    if (byCode != null) {
      if (!byCode.tracked) {
        setState(() => _message = tr.scNotTracked);
        return;
      }
      _addOne(byCode);
      return;
    }
    final found = await _reader.search(code, widget.shopId, limit: 2);
    if (!mounted) return;
    if (found.length == 1) _addOne(found.single);
  }

  Future<void> _addAll() async {
    final all = await _reader.all(widget.shopId);
    if (!mounted) return;
    setState(() {
      final have = {for (final r in _rows) r.product.id};
      for (final p in all) {
        if (!have.contains(p.id)) _rows.add(_Row(p, ''));
      }
    });
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final tr = context.tr;
    return showAppConfirmSheet(
      context,
      title: tr.scDiscardTitle,
      message: tr.scDiscardBody,
      confirmLabel: tr.scDiscard,
    );
  }

  Future<void> _apply() async {
    final tr = context.tr;
    final changing = _differing;
    if (changing.isEmpty || _anyInvalid) return;
    var added = BigInt.zero;
    var taken = BigInt.zero;
    for (final r in changing) {
      final d = r.diff!;
      if (d.isNegative) {
        taken += d.abs();
      } else {
        added += d;
      }
    }
    final ok = await showAppConfirmSheet(
      context,
      title: tr.scConfirmTitle,
      message:
          '${tr.scConfirmBody}\n\n'
          '${tr.scProducts}: ${changing.length}\n'
          '${tr.scAdded}: +${Decimal3.format(added)}\n'
          '${tr.scTakenOff}: −${Decimal3.format(taken)}',
      confirmLabel: changing.length == 1
          ? tr.scApplyOne
          : tr.scApply('${changing.length}'),
    );
    if (!ok || !mounted) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final out = await _service.applyCount(
        shopId: widget.shopId,
        lines: [
          for (final r in _rows)
            if (r.counted != null)
              CountLine(
                productId: r.product.id,
                counted: r.counted!,
                expected: r.product.system,
              ),
        ],
      );
      if (!mounted) return;
      GlobalSnackBar.showSuccess(
        message:
            '${tr.scDoneTitle}. ${tr.scDoneBody('${out.changed}', '${out.matched}')}',
      );
      Navigator.of(context).pop(true);
    } on StockValidationException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = tr.scErrSave;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = tr.scErrSave;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final changing = _differing.length;
    final counted = _rows.where((r) => r.counted != null).length;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmLeave()) nav.pop();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SettingsNavBar(
                backLabel: tr.cancel,
                onBack: () async {
                  final nav = Navigator.of(context);
                  if (await _confirmLeave()) nav.pop();
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                  children: [
                    AppLargeTitle(title: tr.scTitle),
                    AppFormGroup(
                      children: [
                        AppFormRow(
                          label: tr.scSearch,
                          child: AppRowTextField(
                            controller: _search,
                            hint: '…',
                            onChanged: _onQuery,
                            onSubmitted: _onSubmit,
                          ),
                        ),
                      ],
                    ),
                    if (_matches.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppDims.s2),
                        child: AppGroup(
                          children: [
                            for (final p in _matches)
                              AppGroupRow(
                                title: p.name,
                                value: p.systemText,
                                onTap: () => _addOne(p),
                              ),
                          ],
                        ),
                      ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppDims.s2),
                        child: Text(
                          _message!,
                          style: text.bodyMedium!.copyWith(
                            color: colors.danger,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _rows.isEmpty
                                  ? ''
                                  : '${tr.scCounted('$counted')} · ${tr.scDiffs('$changing')}',
                              style: text.bodySmall!.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          Pressable(
                            onTap: _addAll,
                            child: Text(
                              tr.scAddAll,
                              style: text.labelLarge!.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppDims.s6),
                        child: Column(
                          children: [
                            Text(
                              tr.scEmptyTitle,
                              style: text.titleMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppDims.s1),
                            Text(
                              tr.scEmptySub,
                              textAlign: TextAlign.center,
                              style: text.bodyMedium!.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final r in _rows)
                        _CountRow(
                          row: r,
                          onChanged: () => setState(() {
                            r.parse();
                            _message = null;
                          }),
                        ),
                    const SizedBox(height: AppDims.s4),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s2,
                  AppDims.s4,
                  MediaQuery.viewPaddingOf(context).bottom + AppDims.s4,
                ),
                child: AppButton.wide(
                  label: changing == 0
                      ? tr.scApplyNone
                      : changing == 1
                      ? tr.scApplyOne
                      : tr.scApply('$changing'),
                  isLoading: _saving,
                  onPressed: changing > 0 && !_anyInvalid && !_saving
                      ? _apply
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.row, required this.onChanged});

  final _Row row;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final d = row.diff;

    String note;
    Color noteColor;
    if (row.invalid) {
      note = tr.scErrNegative;
      noteColor = colors.danger;
    } else if (d == null) {
      note = tr.scNotCounted;
      noteColor = colors.textHint;
    } else if (d == BigInt.zero) {
      note = tr.scMatches;
      noteColor = colors.success;
    } else {
      note = '${d.isNegative ? '−' : '+'}${Decimal3.format(d.abs())}';
      noteColor = d.isNegative ? colors.danger : colors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDims.s2),
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.s3),
        border: Border.all(
          color: row.invalid ? colors.danger : colors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  note,
                  textDirection: TextDirection.ltr,
                  style: text.bodySmall!.copyWith(
                    color: noteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tr.scSystem,
                style: text.labelSmall!.copyWith(color: colors.textHint),
              ),
              Text(
                row.product.systemText,
                textDirection: TextDirection.ltr,
                style: text.bodyMedium,
              ),
            ],
          ),
          const SizedBox(width: AppDims.s3),
          SizedBox(
            width: 84,
            child: TextField(
              controller: row.ctrl,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: tr.scCountedCol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDims.s2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
