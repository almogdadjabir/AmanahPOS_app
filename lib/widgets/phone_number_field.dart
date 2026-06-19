import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/widgets/login_country.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';

int phoneMaxLength(String value) => value.startsWith('0') ? 10 : 9;

class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool error;
  final String? errorText;
  final LoginCountry country;

  /// When provided, the country chip becomes a tappable dropdown that lets the
  /// user switch country. When null the chip is static (single-country mode).
  final ValueChanged<LoginCountry>? onCountryChanged;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.error = false,
    this.errorText,
    this.country = LoginCountry.sudan,
    this.onCountryChanged,
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

  void _onFocusChange() => _focused.value = _focusNode.hasFocus;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
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
                height: context.isDesktop ? 42 : 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    _CountryChip(
                      country: widget.country,
                      onCountryChanged: widget.onCountryChanged,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 10,
                      ),
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: colors.border,
                      ),
                    ),

                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _maxLength,
                        builder: (context, maxLen, _) {
                          return TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            maxLength: maxLen,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(maxLen),
                            ],
                            style: AppTextStyles.bs400(
                              context,
                              weight: AppTextStyles.semibold,
                              color: colors.textPrimary,
                            ).copyWith(
                              fontSize: context.isDesktop ? 16 : null,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: widget.country.hint,
                              hintTextDirection: TextDirection.ltr,
                              hintStyle: AppTextStyles.bs400(
                                context,
                                color: colors.textHint,
                              ).copyWith(
                                fontSize: context.isDesktop ? 16 : null,
                              ),
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
                              horizontal: AppSpacing.xs,
                            ),
                            child: Icon(
                              SolarIconsOutline.closeCircle,
                              size: 18,
                              color: colors.textHint,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              );
            },
          ),
        ),

      ],
    );
  }
}

/// Country chip shown at the start of the phone field. When [onCountryChanged]
/// is provided it opens a clean dropdown to switch country; otherwise it is a
/// static label.
class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.country, this.onCountryChanged});

  final LoginCountry country;
  final ValueChanged<LoginCountry>? onCountryChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selectable = onCountryChanged != null;
    final dialStyle = AppTextStyles.bs400(
      context,
      weight: AppTextStyles.bold,
      color: colors.textPrimary,
    ).copyWith(fontSize: context.isDesktop ? 16 : null);

    Widget content(VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(country.dialCode,
                    textDirection: TextDirection.ltr, style: dialStyle),
                if (selectable) ...[
                  const SizedBox(width: 2),
                  Icon(SolarIconsOutline.altArrowDown,
                      size: 16, color: colors.textHint),
                ],
              ],
            ),
          ),
        );

    if (!selectable) return content(null);

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(colors.shadow),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
            side: BorderSide(color: colors.border),
          ),
        ),
      ),
      menuChildren: [
        for (final c in LoginCountry.values)
          _CountryMenuItem(
            country: c,
            selected: c == country,
            onTap: () => onCountryChanged!(c),
          ),
      ],
      builder: (context, controller, _) => content(
        () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _CountryMenuItem extends StatelessWidget {
  const _CountryMenuItem({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final LoginCountry country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MenuItemButton(
      onPressed: onTap,
      leadingIcon: Text(country.flag, style: const TextStyle(fontSize: 12)),
      trailingIcon: selected
          ? Icon(SolarIconsOutline.checkCircle, size: 12, color: colors.primary)
          : const SizedBox(width: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              country.label,
              style: AppTextStyles.bs100(
                context,
                weight: selected ? AppTextStyles.bold : AppTextStyles.semibold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              country.dialCode,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bs100(context, color: colors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}