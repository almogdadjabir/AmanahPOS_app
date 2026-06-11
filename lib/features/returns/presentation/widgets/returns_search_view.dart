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
        _SearchHeader(controller: controller),
        Expanded(child: _SearchResults(state: state)),
      ],
    );
  }
}

// ── Search header ────────────────────────────────────────────────────────────

class _SearchHeader extends StatefulWidget {
  const _SearchHeader({required this.controller});
  final TextEditingController controller;

  @override
  State<_SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<_SearchHeader> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      final next = _focus.hasFocus;
      if (_focused != next) setState(() => _focused = next);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: _focused
                ? AppColors.danger.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Focus-ring wrapper
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDims.rMd + 2),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.14),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: CustomSearchField(
              controller: widget.controller,
              onChanged: (q) => context
                  .read<ReturnsBloc>()
                  .add(ReturnsSearchChanged(q)),
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            context.tr.returnSearchHelper,
            style: AppTextStyles.sm100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result area ──────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.state});
  final ReturnsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.searchStatus) {
      ReturnsSearchStatus.idle => const _IdleState(),
      ReturnsSearchStatus.loading => const _LoadingState(),
      ReturnsSearchStatus.failure => _ErrorState(
          message: state.errorMessage,
        ),
      ReturnsSearchStatus.success when state.searchResults.isEmpty =>
        const _EmptyResultsState(),
      _ => _ResultsList(results: state.searchResults),
    };
  }
}

// ── Idle ─────────────────────────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  const _IdleState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Receipt-frame icon
            _ReceiptIconBadge(),
            const SizedBox(height: AppDims.s4),
            Text(
              context.tr.returnFindSale,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                context.tr.returnFindSaleSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.dangerLight.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        // Icon container
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            SolarIconsOutline.undoLeft,
            size: 28,
            color: AppColors.danger,
          ),
        ),
        // Small magnifier badge
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              SolarIconsOutline.magnifier,
              size: 13,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading ──────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s3,
      ),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s2),
      itemBuilder: (_, i) => _SkeletonTile(delay: i * 60),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile({required this.delay});
  final int delay;

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.4 + _anim.value * 0.35;
        return Opacity(
          opacity: opacity,
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s3,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppDims.rSm),
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 8,
                        width: 80,
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 10,
                  width: 56,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppDims.rLg),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2)),
              ),
              child: const Icon(SolarIconsOutline.dangerTriangle,
                  size: 26, color: AppColors.danger),
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              context.tr.returnSearchFailed,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (message?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppDims.s2),
              Text(
                message!.trim(),
                textAlign: TextAlign.center,
                style: AppTextStyles.sm200(context).copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty results ────────────────────────────────────────────────────────────

class _EmptyResultsState extends StatelessWidget {
  const _EmptyResultsState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rLg),
                border: Border.all(color: colors.border),
              ),
              child: Icon(SolarIconsOutline.magnifier,
                  size: 26, color: colors.textHint),
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              context.tr.returnNoSalesFound,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                context.tr.returnNoSalesSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.sm200(context).copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Results list ─────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});
  final List<SaleHistoryItem> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s4,
      ),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s2),
      itemBuilder: (context, index) {
        final sale = results[index];
        return RepaintBoundary(
          child: _SaleResultTile(
            sale: sale,
            onTap: sale.canBeReturned
                ? () => context
                    .read<ReturnsBloc>()
                    .add(ReturnsSaleSelected(sale))
                : null,
          ),
        );
      },
    );
  }
}

// ── Sale result tile ──────────────────────────────────────────────────────────

class _SaleResultTile extends StatelessWidget {
  const _SaleResultTile({required this.sale, required this.onTap});

  final SaleHistoryItem sale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canReturn = sale.canBeReturned;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final dateStr = DateFormat('d MMM · HH:mm', locale)
        .format(sale.createdAt.toLocal());
    final payment = _paymentLabel(context, sale.paymentLabel);
    final items = context.tr.itemCount(sale.itemCount);

    return Opacity(
      opacity: canReturn ? 1.0 : 0.52,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: canReturn
                ? AppColors.danger.withValues(alpha: 0.22)
                : colors.border,
          ),
          boxShadow: canReturn
              ? [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: colors.surface,
          child: InkWell(
            onTap: onTap,
            highlightColor: canReturn
                ? AppColors.dangerLight.withValues(alpha: 0.35)
                : Colors.transparent,
            splashColor: canReturn
                ? AppColors.dangerLight.withValues(alpha: 0.2)
                : Colors.transparent,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent strip ──────────────────────────
                  Container(
                    width: 3,
                    color: canReturn
                        ? AppColors.danger
                        : colors.border,
                  ),

                  // ── Icon ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s3, AppDims.s3, 0, AppDims.s3),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: canReturn
                            ? AppColors.dangerLight
                            : colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppDims.rSm),
                        border: Border.all(
                          color: canReturn
                              ? AppColors.danger.withValues(alpha: 0.18)
                              : colors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Icon(
                        canReturn
                            ? SolarIconsOutline.undoLeft
                            : SolarIconsOutline.forbiddenCircle,
                        size: 18,
                        color: canReturn
                            ? AppColors.danger
                            : colors.textHint,
                      ),
                    ),
                  ),

                  // ── Info ──────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppDims.s3, AppDims.s3, AppDims.s2, AppDims.s3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sale.displayRef,
                            textDirection: ui.TextDirection.ltr,
                            style: AppTextStyles.sm200(context).copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateStr · $payment · $items',
                            style: AppTextStyles.sm100(context).copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!canReturn) ...[
                            const SizedBox(height: 3),
                            Text(
                              _cannotReturnLabel(context),
                              style: AppTextStyles.sm100(context).copyWith(
                                color: colors.textHint,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Amount + arrow ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        0, AppDims.s3, AppDims.s3, AppDims.s3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormat.moneyWithUnit(sale.total),
                          textDirection: ui.TextDirection.ltr,
                          style: AppTextStyles.sm200(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: canReturn
                                ? AppColors.danger
                                : colors.textSecondary,
                            height: 1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (canReturn) ...[
                          const SizedBox(height: 4),
                          DirectionalIcon(
                            icon: SolarIconsOutline.altArrowRight,
                            size: 14,
                            color: AppColors.danger.withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _cannotReturnLabel(BuildContext context) {
    if (sale.isOfflinePending) {
      return context.tr.returnPendingSyncCannotReturn;
    }
    return context.tr.returnAlreadyProcessed(_statusLabel(context, sale.status));
  }
}

String _paymentLabel(BuildContext context, String label) {
  final n = label.toLowerCase().trim();
  if (n.contains('cash')) return context.tr.cash;
  if (n.contains('card')) return context.tr.card;
  if (n.contains('bankak')) return context.tr.bankak;
  if (n.contains('transfer')) return context.tr.bankTransfer;
  if (n.contains('wallet')) return context.tr.wallet;
  return label.trim().isEmpty ? context.tr.payment : label.trim();
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
