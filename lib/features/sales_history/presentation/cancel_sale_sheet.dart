import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/domain/cancel_sale_service.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

/// Asks "Cancel this sale?" and does it. Returns true when the sale was
/// cancelled, false/null when kept.
Future<bool?> showCancelSaleSheet(
  BuildContext context, {
  required CancelSaleService service,
  required String saleId,
  required String receipt,
  required String amount,
}) => showAppSheet<bool>(
  context,
  builder: (_) => CancelSaleSheet(
    service: service,
    saleId: saleId,
    receipt: receipt,
    amount: amount,
  ),
);

class CancelSaleSheet extends StatefulWidget {
  const CancelSaleSheet({
    super.key,
    required this.service,
    required this.saleId,
    required this.receipt,
    required this.amount,
  });

  final CancelSaleService service;
  final String saleId;
  final String receipt;
  final String amount;

  @override
  State<CancelSaleSheet> createState() => _CancelSaleSheetState();
}

class _CancelSaleSheetState extends State<CancelSaleSheet> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final tr = context.tr;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.service.cancel(
        saleId: widget.saleId,
        reason: _reason.text,
      );
      if (!mounted) return;
      switch (r) {
        case CancelOutcome.done:
          navigator.pop(true);
        case CancelOutcome.hasRefunds:
          setState(() {
            _busy = false;
            _error = tr.cnHasRefund;
          });
        case CancelOutcome.notAllowed || CancelOutcome.notFound:
          setState(() {
            _busy = false;
            _error = tr.cnGone;
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = tr.cnErr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return AppSheet(
      title: tr.cnTitle,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s2,
          AppDims.s4,
          AppDims.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton.wide(
                label: tr.cnKeep,
                variant: AppButtonVariant.outline,
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: AppButton.wide(
                label: tr.cnConfirm,
                variant: AppButtonVariant.danger,
                isLoading: _busy,
                onPressed: _busy ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormGroup(
              children: [
                AppFormRow(
                  label: tr.cnReceipt,
                  child: Text(widget.receipt, textDirection: TextDirection.ltr),
                ),
                AppFormRow(
                  label: tr.cnAmount,
                  child: Text(widget.amount, textDirection: TextDirection.ltr),
                ),
                AppFormRow(
                  label: tr.cnReason,
                  child: AppRowTextField(
                    controller: _reason,
                    hint: tr.cnReasonHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              tr.cnBody,
              style: text.bodyMedium!.copyWith(color: colors.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppDims.s3),
              Text(
                _error!,
                style: text.bodyMedium!.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
