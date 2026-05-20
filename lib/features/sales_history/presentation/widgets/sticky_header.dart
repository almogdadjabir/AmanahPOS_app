import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/filter_chips.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stats_row.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class StickyHeader extends StatefulWidget {
  final SaleFilter activeFilter;
  final TextEditingController searchCtrl;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>) applyFilter;
  final ValueChanged<SaleFilter> onFilterSelect;
  final ValueChanged<String> onSearch;

  const StickyHeader({
    super.key,
    required this.activeFilter,
    required this.searchCtrl,
    required this.applyFilter,
    required this.onFilterSelect,
    required this.onSearch,
  });

  @override
  State<StickyHeader> createState() => _StickyHeaderState();
}

class _StickyHeaderState extends State<StickyHeader> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ColoredBox(
      color: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          SaleStatsRow(
            activeFilter: widget.activeFilter,
            applyFilter: widget.applyFilter,
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s2),
            child: _SearchBar(
              controller: widget.searchCtrl,
              focusNode: _focusNode,
              isFocused: _isFocused,
              onChanged: widget.onSearch,
            ),
          ),

          // Filter chips
          FilterChips(
            active: widget.activeFilter,
            onSelect: widget.onFilterSelect,
          ),

          Divider(height: 1, color: colors.border),
        ],
      ),
    );
  }
}


class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 0,
            spreadRadius: 2,
          ),
        ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bs200(context),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surfaceSoft,
          // Borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          // Padding — vertical centers the text in ~44px height
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          // Hint
          hintText: 'Search receipt, amount, payment...',
          hintStyle: AppTextStyles.bs200(context)
              .copyWith(color: colors.textHint),
          // Search icon (left)
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: isFocused ? AppColors.primary : colors.textHint,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 46,
            minHeight: 44,
          ),
          // Clear button (right) — only shown when text exists
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: colors.textSecondary,
                  ),
                ),
              );
            },
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
      ),
    );
  }
}