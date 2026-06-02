import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/app_search_field.dart';
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
  final FocusNode _focusNode = FocusNode();

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

    return AppSearchField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      hint: context.tr.returnSearchHint,
      focusNode: _focusNode,
      suffixWidget: widget.controller.text.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: _clear,
                child: Icon(
                  SolarIconsOutline.closeCircle,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
            )
          : null,
    );
  }
}