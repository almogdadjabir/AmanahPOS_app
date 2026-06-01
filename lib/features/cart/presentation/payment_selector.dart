import 'dart:ui' as ui;

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
  const PaymentSelector({
    super.key,
    required this.paymentMethod,
  });

  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    final isBankak = paymentMethod == 'bankak';

    final bankakAccount = context.select<AuthBloc, String?>((bloc) {
      final account = bloc.state.profile?.bankakAccount?.accountNumber?.trim();
      return account == null || account.isEmpty ? null : account;
    });

    final isConfigured = bankakAccount != null;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(
            title: context.tr.payment,
            subtitle: context.tr.method,
          ),
          const SizedBox(height: AppDims.s3),
          Row(
            children: [
              Expanded(
                child: PaymentButton(
                  icon: SolarIconsOutline.walletMoney,
                  label: context.tr.bankak,
                  subtitle: context.tr.bankTransfer,
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
                  label: context.tr.cash,
                  subtitle: context.tr.payNow,
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
            if (isConfigured)
              _BankakReadyBanner(account: bankakAccount)
            else
              const _BankakSetupBanner(),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

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
          '$title · $subtitle'.toUpperCase(),
          textAlign: TextAlign.end,
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BankakReadyBanner extends StatelessWidget {
  const _BankakReadyBanner({
    required this.account,
  });

  final String account;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.success.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s3),
        child: Row(
          children: [
            Icon(
              SolarIconsOutline.checkCircle,
              size: 20,
              color: colors.success,
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(
                  context.tr.bankakReadyAccount(account),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankakSetupBanner extends StatelessWidget {
  const _BankakSetupBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          RouteStrings.settingsScreen,
        ),
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.warning.withValues(alpha: 0.30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDims.s3),
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
                    context.tr.bankakAccountSetupBanner,
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
        ),
      ),
    );
  }
}