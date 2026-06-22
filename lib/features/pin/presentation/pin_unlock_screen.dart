import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinUnlockScreen extends StatelessWidget {
  const PinUnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) {
        if (state.phase == PinPhase.success) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteStrings.mainScreen,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final locked = state.phase == PinPhase.locked;
        final hasError = state.phase == PinPhase.mismatch;

        return PinScaffold(
          brand: const _UnlockMark(),
          title: 'Enter your PIN',
          subtitle: locked
              ? 'Too many attempts. ${_countdown(state.lockoutRemaining)}'
              : 'Enter your 4-digit PIN to continue.',
          errorText: hasError ? state.errorText : null,
          dots: PinDots(
            filledCount: state.entered.length,
            hasError: hasError,
            success: state.phase == PinPhase.success,
          ),
          keypad: PinKeypad(
            enabled: !locked,
            onDigit: (d) => context.read<PinBloc>().add(PinDigitPressed(d)),
            onBackspace: () => context.read<PinBloc>().add(const PinBackspace()),
          ),
          onDigit: (d) => context.read<PinBloc>().add(PinDigitPressed(d)),
          onBackspace: () => context.read<PinBloc>().add(const PinBackspace()),
          footer: _ForgotPinLink(locked: locked),
        );
      },
    );
  }

  String _countdown(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final time = '$m:${s.toString().padLeft(2, '0')}';
    return 'Try again in $time.';
  }
}

class _UnlockMark extends StatelessWidget {
  const _UnlockMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo — the splash glow, scaled down for continuity.
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.primaryContainer.withValues(alpha: 0.45),
                  colors.primaryContainer.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const AmanaPosLogoMark(size: 72),
        ],
      ),
    );
  }
}

class _ForgotPinLink extends StatelessWidget {
  const _ForgotPinLink({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteStrings.login,
            (route) => false,
          );
        },
        child: Text(
          'Forgot PIN? Use a different account',
          style: AppTextStyles.sm200(context, color: colors.primary)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
