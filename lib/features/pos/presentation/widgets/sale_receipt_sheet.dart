import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SaleReceiptSheet extends StatelessWidget {
  final String? receiptNumber;
  final String clientSaleId;
  final List<PosCartItem> items;
  final double total;
  final String paymentMethod;
  final bool isOffline;
  final String businessName;

  const SaleReceiptSheet({
    super.key,
    required this.receiptNumber,
    required this.clientSaleId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.isOffline,
    required this.businessName,
  });

  static void show(
    BuildContext context, {
    required String? receiptNumber,
    required String clientSaleId,
    required List<PosCartItem> items,
    required double total,
    required String paymentMethod,
    required bool isOffline,
    required String businessName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => SaleReceiptSheet(
        receiptNumber: receiptNumber,
        clientSaleId: clientSaleId,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        isOffline: isOffline,
        businessName: businessName,
      ),
    );
  }

  String get _displayRef =>
      receiptNumber?.isNotEmpty == true
          ? receiptNumber!
          : 'TMP-${clientSaleId.substring(0, 8).toUpperCase()}';

  String get _paymentLabel => switch (paymentMethod) {
        'cash' => 'Cash',
        'bankak' => 'Bankak',
        'card' => 'Card',
        'bank_transfer' => 'Bank Transfer',
        'mobile_wallet' => 'Mobile Wallet',
        _ => paymentMethod,
      };

  String _buildReceiptText() {
    final now = DateTime.now();
    final pad = (int n) => n.toString().padLeft(2, '0');
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr =
        '${now.day} ${months[now.month]} ${now.year} ${pad(now.hour)}:${pad(now.minute)}';

    final sb = StringBuffer();
    sb.writeln('🧾 RECEIPT — AmanaPOS');
    sb.writeln('Ref: $_displayRef');
    if (isOffline) sb.writeln('⚠️  Saved offline — pending sync');
    sb.writeln('Date: $dateStr');
    sb.writeln('─────────────────────────');
    for (final item in items) {
      final name = (item.product.name ?? 'Item').padRight(16).substring(0, 16);
      sb.writeln('$name x${item.quantity}  ${AppFormat.moneyWithUnit(item.lineTotal)}');
    }
    sb.writeln('─────────────────────────');
    sb.writeln('TOTAL:   ${AppFormat.moneyWithUnit(total)}');
    sb.writeln('Payment: $_paymentLabel');
    sb.writeln('─────────────────────────');
    sb.writeln(businessName);
    sb.writeln('Powered by AmanaPOS');
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
    await Share.share(_buildReceiptText(), subject: 'Receipt $_displayRef');
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _displayRef));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt number copied'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
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
              padding: const EdgeInsets.fromLTRB(
                  AppDims.s4, 0, AppDims.s4, AppDims.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isOffline
                              ? AppColors.warningLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isOffline
                              ? Icons.wifi_off_rounded
                              : Icons.check_circle_rounded,
                          color: isOffline ? AppColors.warning : AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOffline ? 'Saved offline' : 'Sale complete!',
                              style: AppTextStyles.bs500(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              isOffline
                                  ? 'Will sync when internet is restored'
                                  : 'Stock updated · Ready to share',
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

                  // Offline banner
                  if (isOffline) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDims.s3),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: AppDims.s2),
                          Expanded(
                            child: Text(
                              'Real receipt number will be assigned once synced. '
                              'You can share this temporary reference now.',
                              style: AppTextStyles.bs100(context).copyWith(
                                color: colors.textPrimary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDims.s4),
                  ],

                  // Receipt number card
                  GestureDetector(
                    onTap: () => _copy(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDims.s4, vertical: AppDims.s4),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            receiptNumber?.isNotEmpty == true
                                ? 'Receipt number'
                                : 'Temporary reference',
                            style: AppTextStyles.sm100(context).copyWith(
                              color: colors.textHint,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppDims.s2),
                          Text(
                            _displayRef,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDims.s2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 13, color: colors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to copy',
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

                  // Items list
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            Divider(
                                height: 1,
                                color: colors.border.withValues(alpha: 0.6)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDims.s4,
                                vertical: AppDims.s3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    items[i].product.name ?? 'Item',
                                    style: AppTextStyles.bs200(context),
                                  ),
                                ),
                                Text(
                                  '×${items[i].quantity}',
                                  style: AppTextStyles.bs100(context).copyWith(
                                      color: colors.textSecondary),
                                ),
                                const SizedBox(width: AppDims.s3),
                                Text(
                                  AppFormat.moneyWithUnit(items[i].lineTotal),
                                  style: AppTextStyles.bs200(context).copyWith(
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDims.s3),

                  // Total row
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppDims.s1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total paid',
                                style: AppTextStyles.bs100(context).copyWith(
                                    color: colors.textSecondary)),
                            Text(_paymentLabel,
                                style: AppTextStyles.sm100(context).copyWith(
                                    color: colors.textHint)),
                          ],
                        ),
                        Text(
                          AppFormat.moneyWithUnit(total),
                          style: AppTextStyles.bs600(context).copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDims.s6),

                  // WhatsApp share
                  FilledButton.icon(
                    onPressed: _shareWhatsApp,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('Share via WhatsApp'),
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

                  // General share
                  OutlinedButton.icon(
                    onPressed: _shareGeneral,
                    icon: Icon(Icons.share_rounded,
                        size: 18, color: colors.textPrimary),
                    label: Text('Share via...',
                        style: TextStyle(color: colors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s2),

                  // Done / New sale
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
                    child: const Text('New sale'),
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
