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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => ReturnSuccessSheet(
        result: result,
        businessName: businessName,
        originalReceiptRef: originalReceiptRef,
      ),
    );
  }

  String get _refundReference {
    return result.refundReference?.trim().isNotEmpty == true
        ? result.refundReference!.trim()
        : 'N/A';
  }

  double get _refundTotal {
    return double.tryParse(result.refundTotal?.toString() ?? '0') ?? 0;
  }

  List<ReturnedItems> get _returnedItems {
    return result.returnedItems ?? const <ReturnedItems>[];
  }

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

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatQty(dynamic value) {
    final qty = double.tryParse(value?.toString() ?? '0') ?? 0;

    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }

    return qty.toStringAsFixed(2);
  }

  String _safeText(String? value, {String fallback = 'Item'}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _buildReceiptText() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');

    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final dateStr =
        '${now.day} ${months[now.month]} ${now.year} ${pad(now.hour)}:${pad(now.minute)}';

    final sb = StringBuffer()
      ..writeln('RETURN RECEIPT — AmanaPOS')
      ..writeln('Ref: $_refundReference')
      ..writeln('Original: $originalReceiptRef')
      ..writeln('Date: $dateStr')
      ..writeln('Status: $_statusLabel')
      ..writeln('─────────────────────────');

    for (final item in _returnedItems) {
      final displayName = _safeText(item.productName);

      final name = displayName.length > 16
          ? displayName.substring(0, 16)
          : displayName.padRight(16);

      final quantity = _formatQty(item.quantity);
      final subtotal = _toDouble(item.subtotal);

      sb.writeln(
        '$name x$quantity  ${AppFormat.moneyWithUnit(subtotal)}',
      );
    }

    sb
      ..writeln('─────────────────────────')
      ..writeln('REFUND:  ${AppFormat.moneyWithUnit(_refundTotal)}')
      ..writeln('Method:  Cash refund')
      ..writeln('─────────────────────────')
      ..writeln(businessName)
      ..writeln('Powered by AmanaPOS');

    return sb.toString();
  }

  Future<void> _shareWhatsApp() async {
    final text = Uri.encodeComponent(_buildReceiptText());
    final uri = Uri.parse('https://wa.me/?text=$text');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareGeneral() async {
    await Share.share(
      _buildReceiptText(),
      subject: 'Return $_refundReference',
    );
  }

  Future<void> _copyRef(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: _refundReference),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reference copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final returnedItems = _returnedItems;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                0,
                AppDims.s4,
                AppDims.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          Icons.check_circle_rounded,
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
                              'Return processed!',
                              style: AppTextStyles.bs500(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_statusLabel · Stock restored · Receipt ready to share',
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
                            'Return reference',
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
                                Icons.copy_rounded,
                                size: 13,
                                color: colors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to copy',
                                style: AppTextStyles.sm100(context).copyWith(
                                  color: colors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDims.s4),

                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: returnedItems.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.all(AppDims.s4),
                      child: Text(
                        'No returned items found',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bs100(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                        : Column(
                      children: [
                        for (int i = 0; i < returnedItems.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                          _ReturnedItemRow(
                            item: returnedItems[i],
                            formatQty: _formatQty,
                            toDouble: _toDouble,
                            safeText: _safeText,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDims.s3),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total refunded',
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

                  FilledButton.icon(
                    onPressed: _shareWhatsApp,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('Share return receipt via WhatsApp'),
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
                    onPressed: _shareGeneral,
                    icon: Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                    label: Text(
                      'Share via...',
                      style: AppTextStyles.bs200(context).copyWith(color: colors.textPrimary),
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
                    child: const Text('Done'),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Text(
            '×$quantity',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
            ),
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