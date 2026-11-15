import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_texts.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinChangeScreen extends StatelessWidget {
  const PinChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (p, c) => p.phase != c.phase,
      listener: (context, state) {
        if (state.phase == PinPhase.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: tr.pinUpdated, isInfo: true);
        }
        if (state.phase == PinPhase.mismatch || state.phase == PinPhase.error) {
          schedulePinReset(context);
        }
      },
      builder: (context, state) {
        final hasError =
            state.phase == PinPhase.mismatch || state.phase == PinPhase.error;
        final String title;
        final String subtitle;
        if (!state.currentVerified) {
          title = tr.pinCurrentTitle;
          subtitle = tr.pinCurrentSubtitle;
        } else if (state.firstEntry.isEmpty) {
          title = tr.pinNewTitle;
          subtitle = tr.pinNewSubtitle;
        } else {
          title = tr.pinConfirmNewTitle;
          subtitle = tr.pinConfirmSubtitle;
        }
        final bloc = context.read<PinBloc>();

        return PinScaffold(
          title: title,
          subtitle: subtitle,
          onCancel: () => Navigator.of(context).pop(),
          cancelLabel: tr.cancel,
          errorText: pinIssueText(tr, state),
          dots: PinDots(
            filledCount: state.entered.length,
            hasError: hasError,
            success: state.phase == PinPhase.success,
          ),
          keypad: PinKeypad(
            enabled: state.phase != PinPhase.success,
            showDelete: state.entered.isNotEmpty,
            onDigit: (d) => bloc.add(PinDigitPressed(d)),
            onBackspace: () => bloc.add(const PinBackspace()),
          ),
          onDigit: (d) => bloc.add(PinDigitPressed(d)),
          onBackspace: () => bloc.add(const PinBackspace()),
        );
      },
    );
  }
}
