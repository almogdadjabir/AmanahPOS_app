import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solar_icons/solar_icons.dart';

class ReturnSuccessSheet extends StatelessWidget {
  final RefundResponseDto result;
  final String businessName;
  final String originalReceiptRef;

  const ReturnSuccessSheet({
    super.key,
    required this.result,
    required this.businessName,
    required this.originalReceiptRef,
  });

  static void show(
      BuildContext context, {
        required RefundResponseDto result,
        required String businessName,
        required String originalReceiptRef,
      }) {
    showAdaptivePanel(
      context,
      desktopWidth: 360,
      builder: (_) => ReturnSuccessSheet(
        result: result,
        businessName: businessName,
        originalReceiptRef: originalReceiptRef,
      ),
    );
  }

  String get _refundReference =>
      result.refundReference?.trim().isNotEmpty == true
          ? result.refundReference!.trim()
          : 'N/A';

  double get _refundTotal =>
      double.tryParse(result.refundTotal?.toString() ?? '0') ?? 0;

  List<ReturnedItems> get _returnedItems =>
      result.returnedItems ?? const <ReturnedItems>[];

  String get _statusLabel {
    switch (result.sale?.status) {
      case 'partial_refund':
        return 'Partial refund';
      case 'refunded':
        return 'Full refund';
      default:
        return 'Return processed';
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(_buildReceiptText(context));
    final uri = Uri.parse('https://wa.me/?text=$text');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareGeneral(BuildContext context) async {
    await Share.share(
      _buildReceiptText(context),
      subject: 'Return $_refundReference',
    );
  }

  Future<void> _copyRef(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: _refundReference),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr.refCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _buildReceiptText( BuildContext context) {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final dateStr =
        '${now.day} ${months[now.month]} ${now.year} ${pad(now.hour)}:${pad(now.minute)}';

    final sb = StringBuffer()
      ..writeln('${context.tr.returnReceipt} — AmanaPOS')
      ..writeln('${context.tr.ref}: $_refundReference')
      ..writeln('${context.tr.original}: $originalReceiptRef')
      ..writeln('${context.tr.date}: $dateStr')
      ..writeln('${context.tr.status}: $_statusLabel')
      ..writeln('─────────────────────────');

    for (final item in _returnedItems) {
      final name = item.productName?.trim() ?? context.tr.item;
      final displayName = name.length > 16 ? name.substring(0, 16) : name.padRight(16);
      final qty = int.tryParse(item.quantity?.toString() ?? '0') ?? 0;
      final subtotal = (item.subtotal is num)
          ? item.subtotal as num
          : double.tryParse(item.subtotal?.toString() ?? '0') ?? 0.0;

      sb.writeln('$displayName x$qty  ${AppFormat.moneyWithUnit(subtotal)}');
    }

    sb
      ..writeln('─────────────────────────')
      ..writeln('${context.tr.refund}: ${AppFormat.moneyWithUnit(_refundTotal)}')
      ..writeln('${context.tr.method}: ${context.tr.cashRefund}')
      ..writeln('─────────────────────────')
      ..writeln(businessName)
      ..writeln(context.tr.poweredByAmanaPOS);

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDims.s3),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppDims.s4, 0, AppDims.s4, AppDims.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          SolarIconsOutline.checkCircle,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.returnProcessed,
                              style: AppTextStyles.bs500(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_statusLabel · ${context.tr.stockRestored} · ${context.tr.receiptReady}',
                              style: AppTextStyles.bs100(context).copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDims.s4),

                  // Copy reference
                  GestureDetector(
                    onTap: () => _copyRef(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppDims.s4),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.tr.returnReference,
                            style: AppTextStyles.sm100(context).copyWith(
                              color: colors.textHint,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppDims.s2),
                          Text(
                            _refundReference,
                            style: AppTextStyles.bs600(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDims.s2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                SolarIconsOutline.copy,
                                size: 13,
                                color: colors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.tr.tapToCopy,
                                style: AppTextStyles.sm100(context)
                                    .copyWith(color: colors.textHint),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDims.s4),

                  // Returned items list
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: _returnedItems.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.all(AppDims.s4),
                      child: Text(
                        context.tr.noReturnedItems,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bs100(context)
                            .copyWith(color: colors.textSecondary),
                      ),
                    )
                        : Column(
                      children: [
                        for (int i = 0; i < _returnedItems.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                          _ReturnedItemRow(
                            item: _returnedItems[i],
                            formatQty: (v) => v.toString(),
                            toDouble: (v) => double.tryParse(v.toString()) ?? 0,
                            safeText: (v, {fallback = 'Item'}) =>
                            v?.trim().isEmpty == true ? fallback : v!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDims.s3),

                  // Total refunded
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr.totalRefunded,
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        AppFormat.moneyWithUnit(_refundTotal),
                        style: AppTextStyles.bs500(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.danger,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDims.s6),

                  // Share buttons
                  FilledButton.icon(
                    onPressed:()=> _shareWhatsApp(context),
                    icon: Icon(SolarIconsOutline.chatRound),
                    label: Text(context.tr.shareReturnWhatsApp),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s2),
                  OutlinedButton.icon(
                    onPressed: ()=> _shareGeneral,
                    icon: Icon(SolarIconsOutline.share, color: colors.textPrimary),
                    label: Text(
                      context.tr.shareVia,
                      style: AppTextStyles.bs200(context)
                          .copyWith(color: colors.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s2),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.surfaceSoft,
                      foregroundColor: colors.textPrimary,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(context.tr.done),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnedItemRow extends StatelessWidget {
  final ReturnedItems item;
  final String Function(dynamic value) formatQty;
  final double Function(dynamic value) toDouble;
  final String Function(String? value, {String fallback}) safeText;

  const _ReturnedItemRow({
    required this.item,
    required this.formatQty,
    required this.toDouble,
    required this.safeText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final productName = safeText(item.productName);
    final quantity = formatQty(item.quantity);
    final subtotal = toDouble(item.subtotal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs200(context).copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Text(
            '×$quantity',
            style: AppTextStyles.bs100(context).copyWith(color: colors.textSecondary),
          ),
          const SizedBox(width: AppDims.s3),
          Text(
            AppFormat.moneyWithUnit(subtotal),
            style: AppTextStyles.bs200(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}