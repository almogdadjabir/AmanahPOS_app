import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// iOS style search field: 38pt, radius 11, tinted fill, magnifier, clear
/// button while typing and an optional trailing action (barcode scan).
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.actionIcon,
    this.onAction,
    this.focusNode,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 18,
            color: colors.textHint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: colors.primary,
              style: TextStyle(
                fontSize: 17,
                height: 1.2,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  color: colors.textHint,
                ),
              ),
            ),
          ),
          if (hasText)
            Pressable(
              onTap: () {
                widget.controller.clear();
                widget.onChanged?.call('');
              },
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  PhosphorIconsFill.xCircle,
                  size: 18,
                  color: colors.textHint,
                ),
              ),
            )
          else if (widget.actionIcon != null)
            Pressable(
              onTap: widget.onAction,
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  widget.actionIcon,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
