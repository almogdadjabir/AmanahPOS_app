import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class PinChangeScreen extends StatelessWidget {
  const PinChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (p, c) => p.phase != c.phase,
      listener: (context, state) {
        if (state.phase == PinPhase.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'PIN updated.', isInfo: true);
        }
      },
      builder: (context, state) {
        final hasError =
            state.phase == PinPhase.mismatch || state.phase == PinPhase.error;
        final String title;
        final String subtitle;
        if (!state.currentVerified) {
          title = 'Enter current PIN';
          subtitle = 'Confirm it\'s you before changing your PIN.';
        } else if (state.firstEntry.isEmpty) {
          title = 'New PIN';
          subtitle = 'Choose a new 4-digit PIN.';
        } else {
          title = 'Confirm new PIN';
          subtitle = 'Enter it once more to confirm.';
        }

        return PinScaffold(
          brand: const _ChangeMark(),
          title: title,
          subtitle: subtitle,
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

class _ChangeMark extends StatelessWidget {
  const _ChangeMark();

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
      child: Icon(PhosphorIconsRegular.password, size: 32, color: colors.primary),
    );
  }
}
