import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/returns/presentation/widgets/custom_search_field.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class ReturnsSearchView extends StatelessWidget {
  const ReturnsSearchView({
    super.key,
    required this.controller,
    required this.state,
  });

  final TextEditingController controller;
  final ReturnsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(controller: controller),
        Expanded(
          child: _SearchResults(state: state),
        ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
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

  void _onSearchChanged(BuildContext context, String query) {
    context.read<ReturnsBloc>().add(
      ReturnsSearchChanged(query),
    );
  }

  void _clearSearch(BuildContext context) {
    widget.controller.clear();
    _onSearchChanged(context, '');
    _focusNode.requestFocus();
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
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isFocused
                    ? [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
                    : null,
              ),
              child: CustomSearchField(
                controller: widget.controller,
                onChanged: (q) =>
                    context.read<ReturnsBloc>().add(ReturnsSearchChanged(q)),

              )
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              context.tr.returnSearchHelper,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textHint,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
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

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.state,
  });

  final ReturnsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (state.searchStatus == ReturnsSearchStatus.idle) {
      return _EmptyState(
        icon: SolarIconsOutline.saleSquare,
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerLight,
        title: context.tr.returnFindSale,
        subtitle: context.tr.returnFindSaleSubtitle,
      );
    }

    if (state.searchStatus == ReturnsSearchStatus.loading) {
      return const _LoadingState();
    }

    if (state.searchStatus == ReturnsSearchStatus.failure) {
      return _EmptyState(
        icon: SolarIconsOutline.dangerTriangle,
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerLight,
        title: context.tr.returnSearchFailed,
        subtitle: state.errorMessage?.trim().isNotEmpty == true
            ? state.errorMessage!.trim()
            : context.tr.pleaseTryAgain,
      );
    }

    if (state.searchResults.isEmpty) {
      return _EmptyState(
        icon: SolarIconsOutline.magnifier,
        iconColor: colors.textHint,
        iconBg: colors.surfaceSoft,
        title: context.tr.returnNoSalesFound,
        subtitle: context.tr.returnNoSalesSubtitle,
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s2),
      itemBuilder: (context, index) {
        final sale = state.searchResults[index];

        return RepaintBoundary(
          child: _SaleResultTile(
            sale: sale,
            onTap: () {
              context.read<ReturnsBloc>().add(
                ReturnsSaleSelected(sale),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.danger,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s5),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.14),
                  ),
                ),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: Icon(
                    icon,
                    size: 36,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleResultTile extends StatelessWidget {
  const _SaleResultTile({
    required this.sale,
    required this.onTap,
  });

  final SaleHistoryItem sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canReturn = sale.canBeReturned;

    return Opacity(
      opacity: canReturn ? 1.0 : 0.52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: canReturn
              ? [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ]
              : null,
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canReturn ? onTap : null,
            highlightColor: AppColors.dangerLight.withValues(alpha: 0.45),
            splashColor: AppColors.dangerLight.withValues(alpha: 0.26),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  _ReturnStatusIcon(canReturn: canReturn),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: _SaleInfo(
                      sale: sale,
                      canReturn: canReturn,
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  _SaleAmount(
                    sale: sale,
                    canReturn: canReturn,
                  ),
                  if (canReturn) ...[
                    const SizedBox(width: AppDims.s2),
                    DirectionalIcon(
                      icon: SolarIconsOutline.altArrowRight,
                      size: 18,
                      color: colors.textHint,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnStatusIcon extends StatelessWidget {
  const _ReturnStatusIcon({
    required this.canReturn,
  });

  final bool canReturn;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = canReturn ? AppColors.danger : colors.textHint;
    final bg = canReturn ? AppColors.dangerLight : colors.surfaceSoft;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.14),
        ),
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(
          canReturn ? SolarIconsOutline.undoLeft : SolarIconsOutline.forbiddenCircle,
          size: 21,
          color: iconColor,
        ),
      ),
    );
  }
}

class _SaleInfo extends StatelessWidget {
  const _SaleInfo({
    required this.sale,
    required this.canReturn,
  });

  final SaleHistoryItem sale;
  final bool canReturn;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sale.displayRef,
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.start,
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
            fontFamily: 'monospace',
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          _metaText(context, sale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (!canReturn) ...[
          const SizedBox(height: 5),
          Text(
            _cannotReturnMessage(context, sale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sm100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _SaleAmount extends StatelessWidget {
  const _SaleAmount({
    required this.sale,
    required this.canReturn,
  });

  final SaleHistoryItem sale;
  final bool canReturn;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 105),
      child: Text(
        AppFormat.moneyWithUnit(sale.total),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bs200(context).copyWith(
          fontWeight: FontWeight.w900,
          color: canReturn ? AppColors.danger : colors.textSecondary,
          height: 1,
          letterSpacing: -0.25,
        ),
      ),
    );
  }
}

String _metaText(BuildContext context, SaleHistoryItem sale) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final date = DateFormat('d MMM · HH:mm', locale).format(
    sale.createdAt.toLocal(),
  );

  final payment = _paymentLabel(context, sale.paymentLabel);
  final itemCount = context.tr.itemCount(sale.itemCount);

  return '$date · $payment · $itemCount';
}

String _paymentLabel(BuildContext context, String label) {
  final normalized = label.toLowerCase().trim();

  if (normalized.contains('cash')) return context.tr.cash;
  if (normalized.contains('card')) return context.tr.card;
  if (normalized.contains('bankak')) return context.tr.bankak;
  if (normalized.contains('transfer')) return context.tr.bankTransfer;
  if (normalized.contains('wallet')) return context.tr.wallet;

  return label.trim().isEmpty ? context.tr.payment : label.trim();
}

String _cannotReturnMessage(BuildContext context, SaleHistoryItem sale) {
  if (sale.isOfflinePending) {
    return context.tr.returnPendingSyncCannotReturn;
  }

  return context.tr.returnAlreadyProcessed(
    _statusLabel(context, sale.status),
  );
}

String _statusLabel(BuildContext context, SaleHistoryStatus status) {
  return switch (status) {
    SaleHistoryStatus.completed => context.tr.completed,
    SaleHistoryStatus.refunded => context.tr.returned,
    SaleHistoryStatus.partialRefund => context.tr.partiallyReturned,
    SaleHistoryStatus.cancelled => context.tr.cancelled,
    SaleHistoryStatus.pending => context.tr.pending,
    SaleHistoryStatus.failed => context.tr.failed,
    _ => context.tr.unknown,
  };
}