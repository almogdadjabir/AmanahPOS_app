import 'dart:ui' as ui;

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/cart/presentation/cart_line.dart';
import 'package:amana_pos/features/cart/presentation/payment_selector.dart';
import 'package:amana_pos/features/cart/presentation/totals_section.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/presentation/widgets/sale_receipt_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ExpandedCart extends StatelessWidget {
  const ExpandedCart({
    super.key,
    required this.onCollapse,
    required this.onCheckout,
  });

  final VoidCallback onCollapse;
  final VoidCallback onCheckout;

  Future<void> _confirmClearCart(BuildContext context) async {
    final colors = context.appColors;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
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
        );
      },
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
      subtotal: state.lastSubtotal,
      taxAmount: state.lastTaxAmount,
      taxName: state.lastTaxName,
      taxRateLabel: formatTaxRate(state.lastTaxRate),
      taxInclusive: state.lastTaxInclusive,
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
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showReceiptSheet(context, state);
          }
        });
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          border: Border(
            top: BorderSide(
              color: colors.border.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          child: BlocBuilder<PosBloc, PosState>(
            buildWhen: (prev, curr) =>
            prev.items != curr.items ||
                prev.paymentMethod != curr.paymentMethod ||
                prev.submitStatus != curr.submitStatus ||
                prev.taxConfig != curr.taxConfig,
            builder: (context, state) {
              final isLoading =
                  state.submitStatus == PosSubmitStatus.loading;

              return Column(
                children: [
                  _ExpandedCartHeader(
                    itemCount: state.itemCount,
                    isLoading: isLoading,
                    onClear: () => _confirmClearCart(context),
                    onCollapse: onCollapse,
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
                        AppDims.s4,
                        AppDims.s3,
                        AppDims.s4,
                        AppDims.s3,
                      ),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) =>
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
                  _ExpandedCartFooter(
                    state: state,
                    isLoading: isLoading,
                    onCheckout: onCheckout,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExpandedCartHeader extends StatelessWidget {
  const _ExpandedCartHeader({
    required this.itemCount,
    required this.isLoading,
    required this.onClear,
    required this.onCollapse,
  });

  final int itemCount;
  final bool isLoading;
  final VoidCallback onClear;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDims.s3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.textHint.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const SizedBox(width: 42, height: 5),
          ),
          const SizedBox(height: AppDims.s4),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s4,
              0,
              AppDims.s4,
              AppDims.s4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ClearButton(
                  enabled: !isLoading,
                  onTap: onClear,
                ),
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr.reviewSale,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.tr.itemCount(itemCount),
                      textAlign: TextAlign.end,
                      style: AppTextStyles.sm200(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        height: 1,
                      ),
                    ),
                  ],
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                _CollapseButton(onTap: onCollapse),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedCartFooter extends StatelessWidget {
  const _ExpandedCartFooter({
    required this.state,
    required this.isLoading,
    required this.onCheckout,
  });

  final PosState state;
  final bool isLoading;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.75),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaymentSelector(paymentMethod: state.paymentMethod),
            TotalsSection(state: state),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDims.s4,
                AppDims.s3,
                AppDims.s4,
                AppDims.s4,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton(
                  onPressed: isLoading ? null : onCheckout,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    disabledBackgroundColor: colors.border,
                    foregroundColor: colors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: isLoading
                        ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: colors.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                        : _CheckoutButtonContent(
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
    );
  }
}

class _CheckoutButtonContent extends StatelessWidget {
  const _CheckoutButtonContent({
    super.key,
    required this.total,
  });

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
            style: AppTextStyles.bs600(context).copyWith(
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
          style: AppTextStyles.bs500(context).copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.danger.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      SolarIconsOutline.trashBinTrash,
                      size: 17,
                      color: colors.danger,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.tr.clear,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              SolarIconsOutline.altArrowDown,
              size: 22,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}