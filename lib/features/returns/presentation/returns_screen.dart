import 'dart:ui' as ui;

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/returns/presentation/widgets/item_selector_view.dart';
import 'package:amana_pos/features/returns/presentation/widgets/return_success_sheet.dart';
import 'package:amana_pos/features/returns/presentation/widgets/returns_search_view.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({
    super.key,
    this.preloadedSale,
  });

  final SaleHistoryItem? preloadedSale;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final preloadedSale = widget.preloadedSale;
    if (preloadedSale != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReturnsBloc>().add(ReturnsPreloadSale(preloadedSale));
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onBackPressed(ReturnsState state) {
    if (state.selectedSale != null) {
      context.read<ReturnsBloc>().add(const ReturnsReset());
      return;
    }

    Navigator.of(context).pop();
  }

  void _onToggleAll() {
    HapticFeedback.selectionClick();
    context.read<ReturnsBloc>().add(const ReturnsAllToggled());
  }

  void _onSuccessShown(BuildContext context, ReturnsState state) {
    final authState = context.read<AuthBloc>().state;
    final businessName = authState.defaultBusiness?.name?.trim().isNotEmpty == true
        ? authState.defaultBusiness!.name!.trim()
        : 'AmanaPOS';

    final originalRef = state.selectedSale?.displayRef ?? '';

    ReturnSuccessSheet.show(
      context,
      result: state.refundResult!,
      businessName: businessName,
      originalReceiptRef: originalRef,
    );

    context.read<ReturnsBloc>().add(const ReturnsReset());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ReturnsBloc, ReturnsState>(
      listenWhen: (previous, current) {
        return previous.submitStatus != current.submitStatus &&
            current.submitStatus == ReturnsSubmitStatus.success &&
            current.refundResult != null;
      },
      listener: _onSuccessShown,
      child: BlocBuilder<ReturnsBloc, ReturnsState>(
        buildWhen: (previous, current) {
          return previous.selectedSale != current.selectedSale ||
              previous.allSelected != current.allSelected ||
              previous.submitStatus != current.submitStatus ||
              previous.searchStatus != current.searchStatus ||
              previous.searchResults != current.searchResults ||
              previous.errorMessage != current.errorMessage ||
              previous.selectedItems != current.selectedItems;
        },
        builder: (context, state) {
          final selectedSale = state.selectedSale;
          final hasSale = selectedSale != null;

          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 0,
              leadingWidth: 58,
              leading: _BackButton(
                onTap: () => _onBackPressed(state),
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: hasSale
                    ? _SaleAppBarTitle(
                  key: ValueKey(selectedSale.id ?? selectedSale.displayRef),
                  sale: selectedSale,
                )
                    : const _DefaultAppBarTitle(
                  key: ValueKey('default-return-title'),
                ),
              ),
              actions: [
                if (hasSale)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppDims.s4,
                    ),
                    child: _ReturnAllButton(
                      allSelected: state.allSelected,
                      onTap: _onToggleAll,
                    ),
                  ),
              ],
            ),
            body: hasSale
                ? ItemSelectorView(state: state)
                : ReturnsSearchView(
              controller: _searchCtrl,
              state: state,
            ),
          );
        },
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      label: context.tr.back,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: DirectionalIcon(
              icon: SolarIconsOutline.altArrowLeft,
              flipInRtl: true,
              size: 22,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnAllButton extends StatelessWidget {
  const _ReturnAllButton({
    required this.allSelected,
    required this.onTap,
  });

  final bool allSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = allSelected ? AppColors.danger : AppColors.dangerLight;
    final foreground = allSelected ? Colors.white : AppColors.danger;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allSelected
                      ? SolarIconsOutline.closeCircle
                      : SolarIconsOutline.undoLeft,
                  size: 14,
                  color: foreground,
                ),
                const SizedBox(width: 5),
                Text(
                  allSelected ? context.tr.deselectAll : context.tr.returnAll,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultAppBarTitle extends StatelessWidget {
  const _DefaultAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              SolarIconsOutline.undoLeft,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AMANAPOS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sm100(context).copyWith(
                  color: AppColors.danger,
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr.processReturn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaleAppBarTitle extends StatelessWidget {
  const _SaleAppBarTitle({
    super.key,
    required this.sale,
  });

  final SaleHistoryItem sale;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final createdAt = DateFormat.yMMMd(locale).format(sale.createdAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sale.displayRef,
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.start,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$createdAt · ${AppFormat.moneyWithUnit(sale.total)}',
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.start,
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            height: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}