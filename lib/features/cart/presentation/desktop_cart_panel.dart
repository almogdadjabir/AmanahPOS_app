import 'dart:ui' as ui;

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/cart/presentation/cart_line.dart';
import 'package:amana_pos/features/cart/presentation/payment_selector.dart';
import 'package:amana_pos/features/cart/presentation/totals_section.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/features/pos/presentation/widgets/sale_receipt_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopCartPanel extends StatelessWidget {
  const DesktopCartPanel({
    super.key,
    required this.onCheckout,
  });

  final VoidCallback onCheckout;

  Future<void> _confirmClearCart(BuildContext context) async {
    final colors = context.appColors;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.rXl),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          context.tr.clearCartQuestion,
          style: AppTextStyles.bs500(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          context.tr.clearCartDescription,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(context.tr.clear),
          ),
        ],
      ),
    );
    if (shouldClear == true && context.mounted) {
      context.read<PosBloc>().add(const PosClearCart());
    }
  }

  void _showReceiptSheet(BuildContext context, PosState state) {
    final authState = context.read<AuthBloc>().state;
    final businessName = authState.defaultBusiness?.name ??
        authState.profile?.fullName ??
        'AmanaPOS';
    SaleReceiptSheet.show(
      context,
      receiptNumber: state.lastReceiptNumber,
      clientSaleId: state.lastClientSaleId ?? '',
      items: state.lastCartSnapshot,
      total: state.lastTotal,
      paymentMethod: state.lastPaymentMethod,
      isOffline: state.lastSaleWasOffline,
      businessName: businessName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) =>
          prev.submitStatus != curr.submitStatus &&
          curr.submitStatus == PosSubmitStatus.success,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) _showReceiptSheet(context, state);
        });
      },
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surface),
        child: BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) =>
              prev.items != curr.items ||
              prev.paymentMethod != curr.paymentMethod ||
              prev.submitStatus != curr.submitStatus,
          builder: (context, state) {
            final isLoading = state.submitStatus == PosSubmitStatus.loading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopCartHeader(
                  itemCount: state.itemCount,
                  isLoading: isLoading,
                  onClear: () => _confirmClearCart(context),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s3),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDims.s3),
                    itemBuilder: (_, index) {
                      final item = state.items[index];
                      return CartLine(
                        key: ValueKey(item.product.id ?? index),
                        item: item,
                      );
                    },
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.border.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PaymentSelector(paymentMethod: state.paymentMethod),
                      TotalsSection(state: state),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s4),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: isLoading ? null : onCheckout,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              disabledBackgroundColor: colors.border,
                              foregroundColor: colors.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              child: isLoading
                                  ? SizedBox(
                                      key: const ValueKey('loading'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: colors.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : _CheckoutContent(
                                      key: const ValueKey('content'),
                                      total: state.total,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Desktop cart header ───────────────────────────────────────────────────────

class _DesktopCartHeader extends StatelessWidget {
  const _DesktopCartHeader({
    required this.itemCount,
    required this.isLoading,
    required this.onClear,
  });

  final int itemCount;
  final bool isLoading;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s4, 0, AppDims.s4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.tr.reviewSale,
              style: AppTextStyles.bs400(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: itemCount > 0
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$itemCount',
                style: AppTextStyles.sm100(context).copyWith(
                  color: itemCount > 0 ? colors.primary : colors.textHint,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const Spacer(),
            if (itemCount > 0)
              MouseRegion(
                cursor: isLoading
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.click,
                child: InkWell(
                  onTap: isLoading ? null : onClear,
                  borderRadius: BorderRadius.circular(8),
                  child: Opacity(
                    opacity: isLoading ? 0.45 : 1,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            SolarIconsOutline.trashBinTrash,
                            size: 14,
                            color: colors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr.clear,
                            style: AppTextStyles.sm200(context).copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Checkout button content ───────────────────────────────────────────────────

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({super.key, required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            money(total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const Spacer(),
        Text(
          context.tr.completeSale,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs400(context).copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }
}

