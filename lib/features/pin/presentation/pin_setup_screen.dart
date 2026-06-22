import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinSetupScreen extends StatelessWidget {
  const PinSetupScreen({super.key});

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
        final confirming = state.phase == PinPhase.confirming ||
            (state.firstEntry.isNotEmpty && state.phase != PinPhase.mismatch);
        final hasError =
            state.phase == PinPhase.mismatch || state.phase == PinPhase.error;

        return PinScaffold(
          brand: const _SetupMark(),
          title: confirming ? 'Confirm your PIN' : 'Create your PIN',
          subtitle: confirming
              ? 'Enter it once more to confirm.'
              : 'Choose a 4-digit PIN to unlock the app.',
          errorText: hasError ? state.errorText : null,
          dots: PinDots(
            filledCount: state.entered.length,
            hasError: hasError,
            success: state.phase == PinPhase.success,
          ),
          keypad: PinKeypad(
            onDigit: (d) => context.read<PinBloc>().add(PinDigitPressed(d)),
            onBackspace: () => context.read<PinBloc>().add(const PinBackspace()),
          ),
          onDigit: (d) => context.read<PinBloc>().add(PinDigitPressed(d)),
          onBackspace: () => context.read<PinBloc>().add(const PinBackspace()),
        );
      },
    );
  }
}

class _SetupMark extends StatelessWidget {
  const _SetupMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer.withValues(alpha: 0.5),
      ),
      child: Icon(Icons.lock_outline_rounded, size: 32, color: colors.primary),
    );
  }
}
