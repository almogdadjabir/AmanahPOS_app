import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int phoneMaxLength(String value) => value.startsWith('0') ? 10 : 9;

class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final InputDecoration? decoration;
  final bool error;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.decoration,
    this.error = false,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late FocusNode _focusNode;

  final ValueNotifier<bool> _focused = ValueNotifier(false);
  final ValueNotifier<int> _maxLength = ValueNotifier(9);
  final ValueNotifier<bool> _hasContent = ValueNotifier(false);

  String _previousText = '';
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
    _previousText = widget.controller.text;
    _hasContent.value = widget.controller.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(PhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.error && !widget.error && widget.controller.text.isEmpty) {
      _completedFired = false;
      _hasContent.value = false;
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    _focused.dispose();
    _maxLength.dispose();
    _hasContent.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    _focused.value = _focusNode.hasFocus;
  }

  void _onTextChanged() {
    final text = widget.controller.text;

    if (text == _previousText) return;

    final newMax = phoneMaxLength(text);
    if (newMax != _maxLength.value) _maxLength.value = newMax;

    if (text.length < _previousText.length) _completedFired = false;

    _previousText = text;
    _hasContent.value = text.isNotEmpty;

    widget.onChanged?.call(text);

    if (text.length >= _maxLength.value && !_completedFired) {
      _completedFired = true;
      _focusNode.unfocus();
      Future.microtask(() => widget.onCompleted?.call(text));
    }
  }

  void _clearField() {
    widget.controller.clear();
    _completedFired = false;
    _hasContent.value = false;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_focusNode.hasFocus) _focusNode.requestFocus();
      },
      child: ValueListenableBuilder(
        valueListenable: _focused,
        builder: (context, focused, _) {
          final borderColor = widget.error
              ? colors.danger
              : focused
              ? colors.primary
              : colors.border;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.lg),

                Text(
                  '+249',
                  style: AppTextStyles.bs400(context,
                      weight: AppTextStyles.bold,
                      color: colors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _maxLength,
                    builder: (context, maxLen, _) {
                      return TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        maxLength: maxLen,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(maxLen),
                        ],
                        style: AppTextStyles.bs400(context,
                            weight: AppTextStyles.semibold,
                            color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '912345678',
                          hintStyle: AppTextStyles.bs400(
                              context, color: colors.textHint),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      );
                    },
                  ),
                ),

                ValueListenableBuilder(
                  valueListenable: _hasContent,
                  builder: (context, hasContent, _) {
                    if (!hasContent) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _clearField,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs),
                        child: Icon(Icons.cancel_rounded,
                            size: 18, color: colors.textHint),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}