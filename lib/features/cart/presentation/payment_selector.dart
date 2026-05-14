import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/cart/presentation/payment_button.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class PaymentSelector extends StatelessWidget {
  final String paymentMethod;

  const PaymentSelector({
    super.key,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final isBankak = paymentMethod == 'bankak';
    final bankakAccount = _bankakAccount(context);
    final isConfigured = bankakAccount != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(
            title: 'PAYMENT',
            subtitle: 'Method',
          ),

          const SizedBox(height: AppDims.s3),

          Row(
            children: [
              Expanded(
                child: PaymentButton(
                  icon: SolarIconsOutline.walletMoney,
                  label: 'Bankak',
                  selected: isBankak,
                  onTap: () {
                    context.read<PosBloc>().add(
                      const PosPaymentMethodChanged('bankak'),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: PaymentButton(
                  icon: SolarIconsOutline.card,
                  label: 'Cash',
                  selected: paymentMethod == 'cash',
                  onTap: () {
                    context.read<PosBloc>().add(
                      const PosPaymentMethodChanged('cash'),
                    );
                  },
                ),
              ),
            ],
          ),

          if (isBankak) ...[
            const SizedBox(height: AppDims.s3),
            isConfigured
                ? _BankakReadyBanner(account: bankakAccount)
                : const _BankakSetupBanner(),
          ],
        ],
      ),
    );
  }

  String? _bankakAccount(BuildContext context) {
    try {
      final account = context
          .read<AuthBloc>()
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

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: colors.border.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Text(
          '$title · $subtitle',
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BankakReadyBanner extends StatelessWidget {
  final String account;

  const _BankakReadyBanner({
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.success.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            SolarIconsOutline.checkCircle,
            size: 20,
            color: colors.success,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'Bankak ready · Account $account',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.success,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankakSetupBanner extends StatelessWidget {
  const _BankakSetupBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        RouteStrings.settingsScreen,
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.warning.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Icon(
              SolarIconsOutline.dangerTriangle,
              size: 20,
              color: colors.warning,
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                'Bankak account is not set up. Tap to open settings.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}