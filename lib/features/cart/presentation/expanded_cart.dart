import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/cart/presentation/cart_line.dart';
import 'package:amana_pos/features/cart/presentation/payment_selector.dart';
import 'package:amana_pos/features/cart/presentation/totals_section.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/sale_receipt_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpandedCart extends StatelessWidget {
  const ExpandedCart({
    super.key,
    required this.onCollapse,
    required this.onCheckout,
  });

  final VoidCallback onCollapse;
  final VoidCallback onCheckout;

  Future<void> _confirmClearCart(BuildContext context) async {
    final bloc = context.read<PosBloc>();
    final tr = context.tr;

    final shouldClear = await showAppConfirmSheet(
      context,
      title: tr.clearCartQuestion,
      message: tr.clearCartDescription,
      confirmLabel: tr.clear,
      cancelLabel: tr.cancel,
    );

    if (shouldClear) {
      bloc.add(const PosClearCart());
      onCollapse();
    }
  }

  void _showReceiptSheet(BuildContext context, PosState state) {
    final authState = context.read<AuthBloc>().state;

    final businessName =
        authState.defaultBusiness?.name ??
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
      child: BlocBuilder<PosBloc, PosState>(
        buildWhen: (prev, curr) =>
            prev.items != curr.items ||
            prev.paymentMethod != curr.paymentMethod ||
            prev.submitStatus != curr.submitStatus ||
            prev.taxConfig != curr.taxConfig,
        builder: (context, state) {
          final isLoading = state.submitStatus == PosSubmitStatus.loading;

          return AppSheet(
            title: context.tr.cart,
            subtitle: context.tr.itemCount(state.itemCount),
            keyboardSafe: false,
            leadingAction: AppSheetAction(
              label: context.tr.clear,
              destructive: true,
              onTap: isLoading ? null : () => _confirmClearCart(context),
            ),
            trailingAction: AppSheetAction(
              label: context.tr.done,
              emphasized: true,
              onTap: onCollapse,
            ),
            footer: AppButton.wide(
              label: context.tr.completeSale,
              isLoading: isLoading,
              onPressed: isLoading ? null : onCheckout,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: AppDims.medium,
                  curve: AppDims.soft,
                  alignment: AlignmentDirectional.topStart,
                  child: Column(
                    children: [
                      for (var i = 0; i < state.items.length; i++) ...[
                        if (i > 0) const _LineDivider(),
                        CartLine(
                          key: ValueKey(state.items[i].product.id ?? i),
                          item: state.items[i],
                        ),
                      ],
                    ],
                  ),
                ),
                PaymentSelector(
                  paymentMethod: state.paymentMethod,
                  padding: const EdgeInsetsDirectional.only(top: AppDims.s4),
                ),
                TotalsSection(
                  state: state,
                  padding: const EdgeInsetsDirectional.only(top: AppDims.s4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LineDivider extends StatelessWidget {
  const _LineDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 52,
      color: context.appColors.border,
    );
  }
}
