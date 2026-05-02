import 'package:amana_pos/features/cart/presentation/payment_button.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentSelector extends StatelessWidget {
  final String paymentMethod;

  const PaymentSelector({
    super.key,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isBankak = paymentMethod == 'bankak';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppDims.s2),

          Row(
            children: [
              Expanded(
                child: PaymentButton(
                  icon: Icons.payments_outlined,
                  label: 'Cash',
                  selected: paymentMethod == 'cash',
                  onTap: () {
                    context.read<PosBloc>().add(
                      const PosPaymentMethodChanged('cash'),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: PaymentButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Bankak',
                  selected: isBankak,
                  onTap: () {
                    context.read<PosBloc>().add(
                      const PosPaymentMethodChanged('bankak'),
                    );
                  },
                ),
              ),
            ],
          ),

          if (isBankak) ...[
            const SizedBox(height: AppDims.s3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDims.s3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppDims.rMd),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                        children: const [
                          TextSpan(text: 'Bankak number: '),
                          TextSpan(
                            text: '123456',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}