import 'dart:ui' as ui;

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/returns/presentation/widgets/item_selector_view.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/returns/presentation/widgets/return_success_sheet.dart';
import 'package:amana_pos/features/returns/presentation/widgets/returns_search_view.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

/// Desktop-only returns panel that slides in from the left side of the
/// sales history layout. Reuses [ReturnsSearchView] and [ItemSelectorView]
/// without a Scaffold — the parent provides [ReturnsBloc] via BlocProvider.value.
class DesktopReturnsSidePanel extends StatelessWidget {
  const DesktopReturnsSidePanel({
    super.key,
    required this.searchController,
    required this.onClose,
  });

  final TextEditingController searchController;
  final VoidCallback onClose;

  void _onBackToSearch(BuildContext context) {
    searchController.clear();
    context.read<ReturnsBloc>().add(const ReturnsReset());
  }

  void _onToggleAll(BuildContext context) {
    HapticFeedback.selectionClick();
    context.read<ReturnsBloc>().add(const ReturnsAllToggled());
  }

  Future<void> _handleSuccess(BuildContext context, ReturnsState state) async {
    final authState = context.read<AuthBloc>().state;
    final businessName =
        authState.defaultBusiness?.name?.trim().isNotEmpty == true
            ? authState.defaultBusiness!.name!.trim()
            : 'AmanaPOS';

    // Capture before reset so they're available after bloc state clears.
    final refundResult = state.refundResult!;
    final originalRef = state.selectedSale?.displayRef ?? '';

    context.read<ReturnsBloc>().add(const ReturnsReset());
    searchController.clear();

    if (!context.mounted) return;
    await showAdaptivePanel<void>(
      context,
      desktopWidth: 360,
      builder: (_) => ReturnSuccessSheet(
        result: refundResult,
        businessName: businessName,
        originalReceiptRef: originalRef,
      ),
    );

    // Close the side panel once the user dismisses the success sheet.
    if (!context.mounted) return;
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocConsumer<ReturnsBloc, ReturnsState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus &&
          current.submitStatus == ReturnsSubmitStatus.success &&
          current.refundResult != null,
      listener: _handleSuccess,
      buildWhen: (previous, current) =>
          previous.selectedSale != current.selectedSale ||
          previous.allSelected != current.allSelected ||
          previous.submitStatus != current.submitStatus ||
          previous.searchStatus != current.searchStatus ||
          previous.searchResults != current.searchResults ||
          previous.errorMessage != current.errorMessage ||
          previous.selectedItems != current.selectedItems,
      builder: (context, state) {
        final hasSale = state.selectedSale != null;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _PanelHeader(
                state: state,
                hasSale: hasSale,
                onBack: () => _onBackToSearch(context),
                onClose: onClose,
                onToggleAll: () => _onToggleAll(context),
              ),
              Expanded(
                child: hasSale
                    ? ItemSelectorView(state: state)
                    : ReturnsSearchView(
                        controller: searchController,
                        state: state,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.state,
    required this.hasSale,
    required this.onBack,
    required this.onClose,
    required this.onToggleAll,
  });

  final ReturnsState state;
  final bool hasSale;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2 + 2,
        ),
        child: Row(
          children: [
            if (hasSale)
              _PanelIconButton(
                icon: SolarIconsOutline.altArrowLeft,
                onTap: onBack,
                color: colors.textSecondary,
                bgColor: colors.surfaceSoft,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    SolarIconsOutline.undoLeft,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: AppDims.s2),
            Expanded(child: _PanelTitle(state: state, hasSale: hasSale)),
            if (hasSale) ...[
              const SizedBox(width: AppDims.s2),
              _ReturnAllChip(
                allSelected: state.allSelected,
                onTap: onToggleAll,
              ),
            ],
            const SizedBox(width: AppDims.s2),
            _PanelIconButton(
              icon: SolarIconsOutline.closeCircle,
              onTap: onClose,
              color: colors.textHint,
              bgColor: colors.surfaceSoft.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.state, required this.hasSale});

  final ReturnsState state;
  final bool hasSale;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (!hasSale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AMANAPOS',
            style: AppTextStyles.sm100(context).copyWith(
              color: AppColors.danger,
              fontSize: 9,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr.processReturn,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    final sale = state.selectedSale!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final createdAt = DateFormat.yMMMd(locale).format(sale.createdAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sale.displayRef,
          textDirection: ui.TextDirection.ltr,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '$createdAt · ${AppFormat.moneyWithUnit(sale.total)}',
          textDirection: ui.TextDirection.ltr,
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDims.rSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rSm),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _ReturnAllChip extends StatelessWidget {
  const _ReturnAllChip({
    required this.allSelected,
    required this.onTap,
  });

  final bool allSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = allSelected ? AppColors.danger : AppColors.dangerLight;
    final fg = allSelected ? Colors.white : AppColors.danger;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppDims.rSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allSelected
                    ? SolarIconsOutline.closeCircle
                    : SolarIconsOutline.undoLeft,
                size: 12,
                color: fg,
              ),
              const SizedBox(width: 4),
              Text(
                allSelected ? context.tr.deselectAll : context.tr.returnAll,
                style: AppTextStyles.sm100(context).copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
