import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Type an amount, optionally label it, add it to the same ticket as items.
class PosKeypadView extends StatefulWidget {
  const PosKeypadView({super.key});

  @override
  State<PosKeypadView> createState() => _PosKeypadViewState();
}

class _PosKeypadViewState extends State<PosKeypadView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const int _maxIntDigits = 9;

  String _raw = '';
  String _note = '';

  double get _value => double.tryParse(_raw) ?? 0;
  bool get _hasValue => _value > 0;

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'del') {
        if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
        return;
      }
      if (key == '.') {
        if (_raw.contains('.')) return;
        _raw = _raw.isEmpty ? '0.' : '$_raw.';
        return;
      }
      final parts = _raw.split('.');
      if (_raw.contains('.')) {
        if (parts[1].length >= 2) return;
      } else {
        if (parts[0].length >= _maxIntDigits) return;
        if (_raw == '0') {
          _raw = key;
          return;
        }
      }
      _raw = '$_raw$key';
    });
  }

  String get _display {
    if (_raw.isEmpty) return '0';
    final parts = _raw.split('.');
    final intPart = AppFormat.money(int.tryParse(parts[0]) ?? 0);
    return _raw.contains('.') ? '$intPart.${parts[1]}' : intPart;
  }

  Future<void> _editNote() async {
    final tr = context.tr;
    // The sheet's TextField is rebuilt while the sheet animates closed, so the
    // controller must live as long as the sheet widget (see _NoteField), not
    // be disposed when showAppSheet's future completes.
    var latest = _note;
    await showAppSheet<void>(
      context,
      builder: (sheetContext) => AppSheet(
        title: tr.posAddNote,
        trailingAction: AppSheetAction(
          label: tr.done,
          emphasized: true,
          onTap: () => Navigator.of(sheetContext).pop(),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s5,
            AppDims.s2,
            AppDims.s5,
            AppDims.s5,
          ),
          child: _NoteField(
            initial: _note,
            hint: tr.posNoteHint,
            onChanged: (value) => latest = value,
            onSubmitted: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _note = latest.trim());
  }

  void _add() {
    if (!_hasValue) return;
    final tr = context.tr;
    HapticFeedback.mediumImpact();
    context.read<PosBloc>().add(
      PosAddCustomAmount(
        amount: _value,
        note: _note.isEmpty ? tr.posCustomAmount : _note,
      ),
    );
    GlobalSnackBar.show(message: tr.posAddedToTicket, isInfo: true);
    setState(() {
      _raw = '';
      _note = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keys shrink on short screens so the whole pad always fits.
        final keyHeight = constraints.maxHeight < 560 ? 48.0 : 56.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppDims.s2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _display,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 52,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: _hasValue
                            ? colors.textPrimary
                            : colors.textHint.withValues(alpha: 0.55),
                      ).tabular,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: Text(
                    _hasValue ? AppFormat.currency : tr.posEnterAmount,
                    style: text.bodyMedium!.copyWith(color: colors.textHint),
                  ),
                ),
                const SizedBox(height: AppDims.s3),
                AnimatedOpacity(
                  duration: AppDims.medium,
                  opacity: _hasValue ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_hasValue,
                    child: _NoteChip(note: _note, onTap: _editNote),
                  ),
                ),
                const SizedBox(height: AppDims.s4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      children: [
                        for (final row in const [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          ['.', '0', 'del'],
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppDims.s2),
                            child: Row(
                              children: [
                                for (int i = 0; i < row.length; i++) ...[
                                  if (i > 0) const SizedBox(width: AppDims.s2),
                                  Expanded(
                                    child: _Key(
                                      keyId: row[i],
                                      height: keyHeight,
                                      onTap: () => _press(row[i]),
                                      onClear: row[i] == 'del'
                                          ? () => setState(() => _raw = '')
                                          : null,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s4,
                    AppDims.s2,
                    AppDims.s4,
                    AppDims.s4,
                  ),
                  child: Pressable(
                    onTap: _hasValue ? _add : null,
                    child: AnimatedContainer(
                      duration: AppDims.medium,
                      curve: AppDims.ease,
                      height: AppDims.buttonHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _hasValue
                            ? colors.primaryContainer
                            : colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      child: Text(
                        _hasValue
                            ? '${tr.posAddToTicket} · ${AppFormat.money(_value)}'
                            : tr.posAddToTicket,
                        style: text.titleMedium!.copyWith(
                          color: _hasValue ? colors.primary : colors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  final String keyId;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _Key({
    required this.keyId,
    required this.height,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isFn = keyId == 'del';

    return Pressable(
      onTap: onTap,
      onLongPress: onClear,
      semanticLabel: isFn ? 'Delete' : keyId,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFn ? Colors.transparent : colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: isFn ? null : Border.all(color: colors.border),
        ),
        child: isFn
            ? Icon(
                PhosphorIconsRegular.backspace,
                size: 26,
                color: colors.textSecondary,
              )
            : Text(
                keyId,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: colors.textPrimary,
                ).tabular,
              ),
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  final String note;
  final VoidCallback onTap;

  const _NoteChip({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final has = note.isNotEmpty;

    return Pressable(
      onTap: onTap,
      child: Container(
        height: 36,
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        decoration: BoxDecoration(
          color: has ? colors.primaryContainer : colors.surfaceSoft,
          borderRadius: AppDims.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.pencilSimple,
              size: 16,
              color: has ? colors.primary : colors.textHint,
            ),
            const SizedBox(width: AppDims.s2),
            Flexible(
              child: Text(
                has ? note : context.tr.posAddNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: has ? colors.textPrimary : colors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Owns the note's [TextEditingController] so it is disposed together with the
/// sheet, after the closing animation, never while the field is still built.
class _NoteField extends StatefulWidget {
  const _NoteField({
    required this.initial,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 120,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: widget.hint),
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted(),
    );
  }
}
