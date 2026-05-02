import 'package:amana_pos/features/cart/presentation/payment_button.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentSelector extends StatelessWidget {
  final String paymentMethod;

  const PaymentSelector({super.key,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        0,
      ),
      child: Row(
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
              icon: Icons.credit_card_rounded,
              label: 'Card',
              selected: paymentMethod == 'card',
              onTap: () {
                context.read<PosBloc>().add(
                  const PosPaymentMethodChanged('card'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}