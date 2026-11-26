import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/returns/presentation/return_items_screen.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail/sale_detail_parts.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One sale: amount first, who and when, items, totals, returns made.
class SaleDetailScreen extends StatefulWidget {
  final SaleHistoryItem item;

  const SaleDetailScreen({super.key, required this.item});

  /// Pushes the detail screen. When the caller has a [SalesHistoryBloc] it
  /// is handed on so a return can update the list behind.
  static Future<void> open(BuildContext context, SaleHistoryItem item) {
    SalesHistoryBloc? bloc;
    try {
      bloc = context.read<SalesHistoryBloc>();
    } catch (_) {
      bloc = null;
    }
    final screen = SaleDetailScreen(item: item);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => bloc == null
            ? screen
            : BlocProvider.value(value: bloc, child: screen),
      ),
    );
  }

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late SaleHistoryItem _sale = widget.item;

  Future<void> _copyRef() async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: _sale.displayRef));
    if (!mounted) return;
    GlobalSnackBar.showSuccess(message: context.tr.shCopied);
  }

  Future<void> _share() async {
    await showReceiptSheet(context, _sale.clientSaleId);
  }

  Future<void> _return() async {
    final updated = await ReturnItemsScreen.open(context, _sale);
    if (updated == null || !mounted) return;
    setState(() => _sale = updated);
    try {
      context.read<SalesHistoryBloc>().add(SalesHistoryItemReplaced(updated));
    } catch (_) {}
  }

  String _paymentValue(BuildContext context) {
    final snap = _sale.bankakSnapshot?.trim() ?? '';
    if (_sale.paymentMethod == 'bankak' && snap.isNotEmpty) {
      final last4 = snap.length > 4 ? snap.substring(snap.length - 4) : snap;
      return context.tr.shBankakAccount(last4);
    }
    return salePaymentName(context, _sale.paymentMethod);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final sale = _sale;

    final failed = sale.status == SaleHistoryStatus.failed;
    final pending =
        !failed &&
        (sale.isOfflinePending || sale.status == SaleHistoryStatus.pending);
    final reason = sale.offlineErrorMessage?.trim() ?? '';

    final cashier = sale.cashierName?.trim() ?? '';
    final shop = sale.shopName?.trim() ?? '';
    final customer = sale.customerName?.trim() ?? '';
    final note = sale.notes?.trim() ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(sharing: false, onShare: _share),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  AppDims.s4,
                ),
                children: [
                  SaleDetailHero(sale: sale),
                  if (pending)
                    SaleBanner(
                      text: tr.shBannerPending,
                      icon: PhosphorIconsRegular.clock,
                    ),
                  if (failed)
                    SaleBanner(
                      text: reason.isEmpty
                          ? tr.shBannerFailedNoReason
                          : tr.shBannerFailed(reason),
                      bad: true,
                      icon: PhosphorIconsRegular.warning,
                    ),
                  AppFormGroup(
                    children: [
                      SaleKvRow(
                        label: tr.shReceipt,
                        onTap: _copyRef,
                        valueWidget: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sale.displayRef,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                kSaleCopyIcon,
                                size: 16,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SaleKvRow(
                        label: tr.shDate,
                        value: saleWhen(context, sale.createdAt),
                      ),
                      if (cashier.isNotEmpty)
                        SaleKvRow(label: tr.shCashier, value: cashier),
                      if (shop.isNotEmpty)
                        SaleKvRow(label: tr.shShop, value: shop),
                      if (customer.isNotEmpty)
                        SaleKvRow(label: tr.shCustomer, value: customer),
                      SaleKvRow(
                        label: tr.shPayment,
                        value: _paymentValue(context),
                      ),
                      if (note.isNotEmpty)
                        SaleKvRow(label: tr.shNote, value: note),
                    ],
                  ),
                  SaleSectionLabel(tr.shItemsHeader(sale.items.length)),
                  SaleItemsCard(sale: sale),
                  const SizedBox(height: 12),
                  SaleTotalsCard(sale: sale),
                  if (sale.refunds.isNotEmpty) ...[
                    SaleSectionLabel(tr.shReturnsHeader),
                    SaleRefundsCard(sale: sale),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (sale.canBeReturned)
              SaleDock(
                child: AppButton.wide(
                  label: tr.shReturnItems,
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.arrowUUpLeft,
                    size: 20,
                  ),
                  onPressed: _return,
                ),
              )
            else
              SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool sharing;
  final VoidCallback onShare;

  const _NavBar({required this.sharing, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      DirectionalIcon(
                        icon: PhosphorIconsRegular.caretLeft,
                        size: 22,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        context.tr.shTitle,
                        style: TextStyle(fontSize: 17, color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: sharing ? null : onShare,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: sharing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(
                          PhosphorIconsRegular.export,
                          size: 24,
                          color: colors.primary,
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
