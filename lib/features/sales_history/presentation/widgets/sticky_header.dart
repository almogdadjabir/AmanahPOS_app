import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/filter_chips.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stats_row.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class StickyHeader extends StatefulWidget {
  const StickyHeader({
    super.key,
    required this.activeFilter,
    required this.searchCtrl,
    required this.applyFilter,
    required this.onFilterSelect,
    required this.onSearch,
  });

  final SaleFilter activeFilter;
  final TextEditingController searchCtrl;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>) applyFilter;
  final ValueChanged<SaleFilter> onFilterSelect;
  final ValueChanged<String> onSearch;

  @override
  State<StickyHeader> createState() => _StickyHeaderState();
}

class _StickyHeaderState extends State<StickyHeader> {
  final FocusNode _focusNode = FocusNode();

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_isFocused == _focusNode.hasFocus) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SaleStatsRow(
              activeFilter: widget.activeFilter,
              applyFilter: widget.applyFilter,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDims.s4,
                AppDims.s3,
                AppDims.s4,
                AppDims.s2,
              ),
              child: _SearchBar(
                controller: widget.searchCtrl,
                focusNode: _focusNode,
                isFocused: _isFocused,
                onChanged: widget.onSearch,
              ),
            ),
            FilterChips(
              active: widget.activeFilter,
              onSelect: widget.onFilterSelect,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.12),
            blurRadius: 0,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bs200(context).copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surfaceSoft,
          isDense: true,
          border: _border(colors.border),
          enabledBorder: _border(colors.border),
          focusedBorder: _border(
            colors.primary,
            width: 1.5,
          ),
          contentPadding: const EdgeInsetsDirectional.symmetric(
            vertical: 13,
          ),
          hintText: context.tr.searchReceiptAmountPaymentHint,
          hintStyle: AppTextStyles.bs200(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            SolarIconsOutline.magnifier,
            size: 20,
            color: isFocused ? colors.primary : colors.textHint,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 46,
            minHeight: 44,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final hasText = value.text.trim().isNotEmpty;

              if (!hasText) {
                return const SizedBox.shrink();
              }

              return _ClearSearchButton(
                onTap: () {
                  controller.clear();
                  onChanged('');
                  focusNode.requestFocus();
                },
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

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}

class _ClearSearchButton extends StatelessWidget {
  const _ClearSearchButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      label: context.tr.clearSearch,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  SolarIconsOutline.closeCircle,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}