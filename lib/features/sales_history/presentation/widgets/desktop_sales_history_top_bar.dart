import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Desktop sales-history header: a live-search field, a view-mode tab switch
/// (Transactions / Reports) centred in the remaining space, and a refresh
/// action — mirrors [DesktopInventoryTopBar] so Sales History reads as the
/// same control surface as the rest of the app's desktop views.
class DesktopSalesHistoryTopBar extends StatelessWidget {
  const DesktopSalesHistoryTopBar({
    super.key,
    required this.activeView,
    required this.onViewChanged,
    required this.searchController,
    required this.onRefresh,
  });

  final SalesView activeView;
  final ValueChanged<SalesView> onViewChanged;
  final TextEditingController searchController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchField(
              controller: searchController,
              colors: colors,
            ),
          ),
          const Spacer(),
          SalesViewTabSwitch(
            active: activeView,
            onChanged: onViewChanged,
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(SolarIconsOutline.refresh),
            style: IconButton.styleFrom(
              foregroundColor: colors.textSecondary,
              backgroundColor: colors.surfaceSoft.withValues(alpha: 0.65),
              side: BorderSide(color: colors.border.withValues(alpha: 0.75)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.colors,
  });

  final TextEditingController controller;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: context.tr.searchSalesHistoryHint,
            hintStyle: AppTextStyles.bs200(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(
              SolarIconsOutline.magnifier,
              size: 18,
              color: colors.textHint,
            ),
            suffixIcon: hasText
                ? InkWell(
                    onTap: controller.clear,
                    borderRadius: BorderRadius.circular(999),
                    child: Icon(
                      SolarIconsOutline.closeCircle,
                      size: 18,
                      color: colors.textHint,
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDims.s3,
              vertical: AppDims.s2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}
