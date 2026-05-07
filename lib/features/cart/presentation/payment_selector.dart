// ════════════════════════════════════════════════════════════════════════════
// lib/features/cart/presentation/payment_selector.dart
// ════════════════════════════════════════════════════════════════════════════

import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/cart/presentation/payment_button.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentSelector extends StatelessWidget {
  final String paymentMethod;

  const PaymentSelector({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final colors    = context.appColors;
    final isBankak  = paymentMethod == 'bankak';

    // Read Bankak account once — SettingsBloc is provided at app level.
    // Falls back to null if bloc is not in scope (shouldn't happen in prod).
    final String? bankakAccount = _bankakAccount(context);
    final bool    isConfigured  = bankakAccount != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s3, AppDims.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: AppTextStyles.bs200(context).copyWith(
              color:      colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppDims.s2),

          Row(
            children: [
              Expanded(
                child: PaymentButton(
                  icon:     Icons.payments_outlined,
                  label:    'Cash',
                  selected: paymentMethod == 'cash',
                  onTap: () => context.read<PosBloc>().add(
                    const PosPaymentMethodChanged('cash'),
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: PaymentButton(
                  icon:     Icons.account_balance_wallet_outlined,
                  label:    'Bankak',
                  selected: isBankak,
                  onTap: () => context.read<PosBloc>().add(
                    const PosPaymentMethodChanged('bankak'),
                  ),
                ),
              ),
            ],
          ),

          // ── Bankak status banner ───────────────────────────────────────
          if (isBankak) ...[
            const SizedBox(height: AppDims.s3),
            isConfigured
                ? _BankakReadyBanner(account: bankakAccount!)
                : _BankakSetupBanner(),
          ],
        ],
      ),
    );
  }

  String? _bankakAccount(BuildContext context) {
    try {
      final account = context
          .read<SettingsBloc>()
          .state
          .profile
          ?.bankakAccount
          ?.accountNumber
          ?.trim();
      return (account == null || account.isEmpty) ? null : account;
    } catch (_) {
      return null;
    }
  }
}

// ── Bankak is configured ──────────────────────────────────────────────────────

class _BankakReadyBanner extends StatelessWidget {
  final String account;
  const _BankakReadyBanner({required this.account});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3, vertical: AppDims.s3),
      decoration: BoxDecoration(
        color:        green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border:       Border.all(color: green.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: green,
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bankak ready',
                  style: AppTextStyles.bs200(context).copyWith(
                    color:      green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Account ${_mask(account)}',
                  style: AppTextStyles.bs100(context).copyWith(
                    color:      const Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mask(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }
}

// ── Bankak not configured ─────────────────────────────────────────────────────

class _BankakSetupBanner extends StatelessWidget {
  const _BankakSetupBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const amber  = Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color:        amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border:       Border.all(color: amber.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: amber,
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bankak account not set up',
                  style: AppTextStyles.bs200(context).copyWith(
                    color:      colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Add your Bankak account number in Settings to accept Bankak payments.',
                  style: AppTextStyles.bs100(context).copyWith(
                    color:      colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height:     1.4,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteStrings.settingsScreen,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s3, vertical: 6),
                    decoration: BoxDecoration(
                      color:        amber,
                      borderRadius: BorderRadius.circular(AppDims.rSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Setup Bankak',
                          style: AppTextStyles.bs100(context).copyWith(
                            color:      Colors.white,
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
      ),
    );
  }
}