import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_texts.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinSetupScreen extends StatelessWidget {
  const PinSetupScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final bloc = context.read<PinBloc>();
    final navigator = Navigator.of(context);
    // Let the dots show their green moment first.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!context.mounted) return;

    final userId = bloc.enrollUser?.id;
    final service = getIt<BiometricUnlockService>();
    final kind = userId == null ? null : await service.offerFor(userId);
    if (kind != null && context.mounted) {
      final turnOn = await _askBiometric(context, kind);
      if (turnOn == true && userId != null && context.mounted) {
        await service.enable(userId, context.tr.pinBiometricReason);
      }
    }
    navigator.pushNamedAndRemoveUntil(RouteStrings.mainScreen, (_) => false);
  }

  Future<bool?> _askBiometric(BuildContext context, BiometricKind kind) {
    final tr = context.tr;
    final method = biometricLabel(tr, kind);
    return showAppSheet<bool>(
      context,
      builder: (ctx) => AppSheet(
        title: tr.pinBiometricEnableTitle(method),
        subtitle: tr.pinBiometricEnableBody,
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton.wide(
              label: tr.pinBiometricEnable(method),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: AppDims.s2),
            AppButton.wide(
              label: tr.pinBiometricNotNow,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ctx.appColors.primaryContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: BiometricGlyph(kind: kind, size: 44),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) {
        if (state.phase == PinPhase.success) _finish(context);
        if (state.phase == PinPhase.mismatch || state.phase == PinPhase.error) {
          schedulePinReset(context);
        }
      },
      builder: (context, state) {
        final confirming =
            state.phase == PinPhase.confirming ||
            (state.firstEntry.isNotEmpty && state.phase != PinPhase.mismatch);
        final hasError =
            state.phase == PinPhase.mismatch || state.phase == PinPhase.error;
        final bloc = context.read<PinBloc>();

        return PinScaffold(
          title: confirming ? tr.pinConfirmTitle : tr.pinCreateTitle,
          subtitle: confirming ? tr.pinConfirmSubtitle : tr.pinCreateSubtitle,
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
