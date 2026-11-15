import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/providers/feature_bloc_providers.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/returns/presentation/widgets/return_done_sheet.dart';
import 'package:amana_pos/features/returns/presentation/widgets/return_lines_card.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail/sale_detail_parts.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Return flow for one sale: tick lines, set quantities, confirm, done.
class ReturnItemsScreen extends StatelessWidget {
  final SaleHistoryItem sale;

  const ReturnItemsScreen({super.key, required this.sale});

  /// Pushes the return flow for [sale]. Resolves to the refreshed sale when a
  /// return was recorded, or null when the user backed out.
  static Future<SaleHistoryItem?> open(
    BuildContext context,
    SaleHistoryItem sale,
  ) => Navigator.of(context).push<SaleHistoryItem?>(
    MaterialPageRoute<SaleHistoryItem?>(
      builder: (_) => ReturnItemsScreen(sale: sale),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FeatureBlocProviders.returns(child: _ReturnBody(sale: sale));
  }
}

class _ReturnBody extends StatefulWidget {
  final SaleHistoryItem sale;

  const _ReturnBody({required this.sale});

  @override
  State<_ReturnBody> createState() => _ReturnBodyState();
}

class _ReturnBodyState extends State<_ReturnBody> {
  final TextEditingController _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ReturnsBloc>().add(ReturnsStarted(widget.sale));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _isCash => widget.sale.paymentMethod == 'cash';

  Future<void> _refund(ReturnsState state) async {
    final tr = context.tr;
    final amount = saleMoney(context, state.refundTotal);
    FocusScope.of(context).unfocus();
    final ok = await showAppConfirmSheet(
      context,
      title: tr.rtConfirmTitle(amount),
      message: _isCash
          ? tr.rtConfirmBodyCash(amount)
          : tr.rtConfirmBodyOther(
              amount,
              salePaymentName(context, widget.sale.paymentMethod),
            ),
      confirmLabel: tr.rtConfirmGo,
    );
    if (!ok || !mounted) return;
    context.read<ReturnsBloc>().add(
      ReturnsSubmitted(notes: _reason.text.trim()),
    );
  }

  Future<void> _onSubmit(BuildContext ctx, ReturnsState state) async {
    if (state.submitStatus == ReturnsSubmitStatus.failure) {
      GlobalSnackBar.showError(message: ctx.tr.rtFailed);
      return;
    }
    final result = state.refundResult;
    if (state.submitStatus != ReturnsSubmitStatus.success || result == null) {
      return;
    }
    final business = ctx.read<AuthBloc>().state.defaultBusiness?.name;
    await showReturnDoneSheet(
      ctx,
      result: result,
      sale: widget.sale,
      businessName: (business?.trim().isNotEmpty ?? false)
          ? business!.trim()
          : 'AmanaPOS',
    );
    if (!mounted) return;

    SaleHistoryItem? refreshed;
    final id = widget.sale.id;
    if (id != null) {
      final res = await getIt<SalesHistoryUseCase>().getSaleById(id);
      refreshed = res.fold((_) => null, (s) => s);
    }
    refreshed ??= widget.sale.copyWith(
      status: result.isFullRefund
          ? SaleHistoryStatus.refunded
          : SaleHistoryStatus.partialRefund,
    );
    if (!mounted) return;
    Navigator.of(context).pop(refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final sale = widget.sale;

    return BlocConsumer<ReturnsBloc, ReturnsState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: _onSubmit,
      builder: (context, state) {
        final bloc = context.read<ReturnsBloc>();
        final loading = state.submitStatus == ReturnsSubmitStatus.loading;
        final hasSel = state.hasSelection;
        final customer = sale.customerName?.trim() ?? '';

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  _TopBar(
                    title: tr.rtTitle,
                    cancel: tr.cancel,
                    onCancel: loading
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        4,
                        AppDims.s4,
                        AppDims.s4,
                      ),
                      children: [
                        _MiniSale(
                          sale: sale,
                          subtitle: customer.isEmpty
                              ? saleWhen(context, sale.createdAt)
                              : '${saleWhen(context, sale.createdAt)} · $customer',
                        ),
                        _SectionRow(
                          title: tr.rtItemsToReturn,
                          action: hasSel ? tr.rtClear : tr.rtSelectAll,
                          onAction: () {
                            HapticFeedback.selectionClick();
                            if (hasSel) {
                              // Clear everything that is selected.
                              for (final id in state.selected.keys.toList()) {
                                bloc.add(ReturnsLineToggled(id));
                              }
                            } else {
                              bloc.add(const ReturnsAllToggled());
                            }
                          },
                        ),
                        ReturnLinesCard(
                          lines: sale.items,
                          selected: state.selected,
                          onToggle: (id) => bloc.add(ReturnsLineToggled(id)),
                          onQuantity: (id, q) =>
                              bloc.add(ReturnsQuantityChanged(id, q)),
                        ),
                        const SizedBox(height: 29),
                        AppFormGroup(
                          children: [
                            AppFormRow(
                              label: tr.rtReason,
                              labelWidth: 90,
                              child: AppRowTextField(
                                controller: _reason,
                                hint: tr.rtOptional,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            SaleKvRow(
                              label: tr.rtPayBack,
                              value: salePaymentName(
                                context,
                                sale.paymentMethod,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SaleDock(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasSel)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              tr.rtFooter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textHint,
                              ),
                            ),
                          ),
                        AppButton.wide(
                          label: hasSel
                              ? tr.rtRefundButton(
                                  saleMoney(context, state.refundTotal),
                                )
                              : tr.rtPickItems,
                          isLoading: loading,
                          onPressed: hasSel && !loading
                              ? () => _refund(state)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String cancel;
  final VoidCallback? onCancel;

  const _TopBar({
    required this.title,
    required this.cancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Pressable(
                onTap: onCancel,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 18, end: 10),
                  child: Text(
                    cancel,
                    style: TextStyle(fontSize: 17, color: colors.primary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 96),
        ],
      ),
    );
  }
}

class _MiniSale extends StatelessWidget {
  final SaleHistoryItem sale;
  final String subtitle;

  const _MiniSale({required this.sale, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SalePaymentTile(method: sale.paymentMethod, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      sale.displayRef,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                saleMoney(context, sale.total),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionRow({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: colors.textHint),
            ),
          ),
          Pressable(
            onTap: onAction,
            child: Text(
              action,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
