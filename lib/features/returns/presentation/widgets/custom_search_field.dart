import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class CustomSearchField extends StatefulWidget {
  const CustomSearchField({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  bool _hasFocus = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            textAlignVertical: TextAlignVertical.center,
            style: AppTextStyles.bs200(context).copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              filled: true,
              fillColor: colors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.danger, width: 1.5),
              ),
              hintText: context.tr.returnSearchHint,
              hintStyle: AppTextStyles.bs200(context).copyWith(color: colors.textHint),
            ),
          ),
          // Prefix icon
          Positioned(
            left: 12,
            child: Icon(
              SolarIconsOutline.magnifier,
              color: _hasFocus ? AppColors.danger : colors.textHint,
              size: 20,
            ),
          ),
          // Suffix clear button
          if (widget.controller.text.isNotEmpty)
            Positioned(
              right: 12,
              child: GestureDetector(
                onTap: _clear,
                child: Icon(
                  SolarIconsOutline.closeCircle,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}