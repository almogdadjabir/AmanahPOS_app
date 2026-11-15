import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail/sale_detail_parts.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _whatsappGreen = Color(0xFF1FA855);

/// "Return recorded": reference, amount, WhatsApp share, Done.
/// Resolves when the sheet closes by any route; the caller then leaves.
Future<void> showReturnDoneSheet(
  BuildContext context, {
  required RefundResponseDto result,
  required SaleHistoryItem sale,
  required String businessName,
}) {
  return showAdaptivePanel<void>(
    context,
    builder: (_) => _ReturnDoneSheet(
      result: result,
      sale: sale,
      businessName: businessName,
    ),
  );
}

class _ReturnDoneSheet extends StatelessWidget {
  final RefundResponseDto result;
  final SaleHistoryItem sale;
  final String businessName;

  const _ReturnDoneSheet({
    required this.result,
    required this.sale,
    required this.businessName,
  });

  String _text(BuildContext context) {
    final tr = context.tr;
    final now = DateTime.now();
    final sb = StringBuffer()
      ..writeln('${tr.returnReceipt} — AmanaPOS')
      ..writeln('${tr.ref}: ${result.safeRefundReference}')
      ..writeln('${tr.original}: ${sale.displayRef}')
      ..writeln('${tr.date}: ${saleWhen(context, now)}')
      ..writeln('─────────────────────────');
    for (final item in result.returnedItems ?? const <ReturnedItems>[]) {
      final name = item.productName?.trim() ?? tr.item;
      final qty = double.tryParse(item.quantity ?? '') ?? 0;
      final sub = double.tryParse(item.subtotal ?? '') ?? 0;
      sb.writeln('$name x${saleQty(qty)}  ${saleMoney(context, sub)}');
    }
    sb
      ..writeln('─────────────────────────')
      ..writeln(
        '${tr.refund}: ${saleMoney(context, result.refundTotalAsDouble)}',
      )
      ..writeln('${tr.method}: ${salePaymentName(context, sale.paymentMethod)}')
      ..writeln('─────────────────────────')
      ..writeln(businessName)
      ..writeln(tr.poweredByAmanaPOS);
    return sb.toString();
  }

  Future<void> _whatsapp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_text(context))}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppDims.s4, 12, AppDims.s4, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(top: 8, bottom: 14),
              decoration: BoxDecoration(
                color: colors.successContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.check,
                size: 36,
                color: colors.success,
              ),
            ),
          ),
          Text(
            tr.rtDoneTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: saleNumber(result.refundTotalAsDouble),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      color: colors.textPrimary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                  TextSpan(
                    text: ' ${tr.shUnit}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textHint,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr.rtDoneBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 21 / 15,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AppFormGroup(
            children: [
              SaleKvRow(
                label: tr.rtReference,
                value: result.safeRefundReference,
                numeric: true,
              ),
              SaleKvRow(
                label: tr.shReceipt,
                value: sale.displayRef,
                numeric: true,
              ),
              SaleKvRow(
                label: tr.shDate,
                value: saleWhen(context, DateTime.now()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetButton(
            label: tr.rtShareWhatsApp,
            icon: PhosphorIconsRegular.whatsappLogo,
            background: _whatsappGreen,
            foreground: Colors.white,
            onTap: () => _whatsapp(context),
          ),
          const SizedBox(height: 10),
          _SheetButton(
            label: tr.done,
            background: colors.surfaceSoft,
            foreground: colors.textPrimary,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppDims.rMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
