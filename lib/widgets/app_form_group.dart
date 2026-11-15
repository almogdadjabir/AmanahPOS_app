import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inset grouped form card (iOS Settings): rounded surface, hairlines inset
/// 16pt from the start. Children are [AppFormRow]s or any widget.
class AppFormGroup extends StatelessWidget {
  final List<Widget> children;
  final String? header;
  final String? footer;

  const AppFormGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 7),
            child: Text(
              header!,
              style: text.bodySmall!.copyWith(
                fontSize: 13,
                color: colors.textHint,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: AppDims.borderLg,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
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
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
            child: Text(
              footer!,
              style: text.bodySmall!.copyWith(
                fontSize: 13,
                color: colors.textHint,
              ),
            ),
          ),
      ],
    );
  }
}

/// One form row: fixed-width label at the start, content filling the rest.
class AppFormRow extends StatelessWidget {
  final String? label;
  final double labelWidth;
  final Widget child;
  final VoidCallback? onTap;
  final bool chevron;
  final double minHeight;
  final CrossAxisAlignment align;

  const AppFormRow({
    super.key,
    required this.child,
    this.label,
    this.labelWidth = 104,
    this.onTap,
    this.chevron = false,
    this.minHeight = 52,
    this.align = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          crossAxisAlignment: align,
          children: [
            if (label != null) ...[
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: labelWidth),
                child: Text(
                  label!,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(fontSize: 17, color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: AppDims.s2),
            ],
            Expanded(child: child),
            if (chevron) ...[
              const SizedBox(width: AppDims.s2),
              DirectionalIcon(
                icon: PhosphorIconsRegular.caretRight,
                size: 18,
                color: colors.borderStrong,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Pressable(onTap: onTap, scale: 1, child: row);
  }
}

/// Text input that lives inside an [AppFormRow]. Borderless.
class AppRowTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool numeric;
  final int maxLines;
  final String? suffix;
  final TextCapitalization textCapitalization;

  const AppRowTextField({
    super.key,
    required this.controller,
    this.hint,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.numeric = false,
    this.maxLines = 1,
    this.suffix,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      keyboardType:
          keyboardType ??
          (numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text),
      textInputAction: textInputAction ?? TextInputAction.next,
      textCapitalization: numeric
          ? TextCapitalization.none
          : textCapitalization,
      inputFormatters: inputFormatters,
      textAlign: numeric ? TextAlign.end : TextAlign.start,
      textDirection: numeric ? TextDirection.ltr : null,
      cursorColor: colors.primary,
      style: TextStyle(
        fontSize: 17,
        color: colors.textPrimary,
        fontFeatures: numeric ? const [FontFeature.tabularFigures()] : null,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 14 : 0),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 17, color: colors.textHint),
      ),
    );

    if (suffix == null) return field;

    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AppDims.s2),
        Text(
          suffix!,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.textHint,
          ),
        ),
      ],
    );
  }
}

/// Value display used inside an [AppFormRow] for rows that open a picker.
class AppRowValue extends StatelessWidget {
  final String text;
  final bool placeholder;
  final bool numeric;
  final Widget? leading;

  const AppRowValue(
    this.text, {
    super.key,
    this.placeholder = false,
    this.numeric = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: numeric ? TextAlign.end : TextAlign.start,
            textDirection: numeric ? TextDirection.ltr : null,
            style: TextStyle(
              fontSize: 17,
              color: placeholder ? colors.textHint : colors.textSecondary,
              fontFeatures: numeric
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Row with a title, optional hint line and a switch at the end.
class AppSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 17, color: colors.textPrimary),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: colors.textHint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDims.s3),
            CupertinoSwitch(
              value: value,
              activeTrackColor: colors.primary,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
