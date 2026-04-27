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
  int _maxLength = 9;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final newMax = phoneMaxLength(text);

    if (newMax != _maxLength) setState(() => _maxLength = newMax);

    widget.onChanged?.call(text);

    if (text.length >= _maxLength) {
      _focusNode.unfocus();
      widget.onCompleted?.call(text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool error = widget.error;

    final borderColor = error
        ? colors.danger
        : _focused
        ? colors.primary
        : colors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Text(
            '+249',
            style: AppTextStyles.bs400(context,
                weight: AppTextStyles.bold, color: colors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              maxLength: _maxLength,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_maxLength),
              ],
              style: AppTextStyles.bs400(context,
                  weight: AppTextStyles.semibold, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: '912345678',
                hintStyle:
                AppTextStyles.bs400(context, color: colors.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}