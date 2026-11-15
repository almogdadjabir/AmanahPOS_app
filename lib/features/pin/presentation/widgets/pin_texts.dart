import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Localized text for the reason the last attempt failed, or null.
String? pinIssueText(AppLocalizations tr, PinState state) {
  final hasError =
      state.phase == PinPhase.mismatch || state.phase == PinPhase.error;
  if (!hasError) return null;
  return switch (state.issue) {
    PinIssue.mismatch => tr.pinMismatch,
    PinIssue.wrong => tr.pinWrong,
    PinIssue.taken => tr.pinTaken,
    _ => tr.pinUnavailable,
  };
}

/// After a wrong PIN has been shown for a moment, return to an empty entry.
void schedulePinReset(BuildContext context) {
  final bloc = context.read<PinBloc>();
  Future.delayed(const Duration(milliseconds: 900), () {
    if (!bloc.isClosed) bloc.add(const PinCleared());
  });
}

String biometricLabel(AppLocalizations tr, BiometricKind kind) =>
    switch (kind) {
      BiometricKind.face => tr.pinBiometricFace,
      BiometricKind.fingerprint => tr.pinBiometricFingerprint,
      BiometricKind.other => tr.pinBiometricGeneric,
    };

/// The glyph for the biometric key: a Face ID style face, or a fingerprint.
class BiometricGlyph extends StatelessWidget {
  const BiometricGlyph({super.key, required this.kind, this.size = 36});

  final BiometricKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.primary;
    if (kind != BiometricKind.face) {
      return Icon(
        PhosphorIconsRegular.fingerprintSimple,
        size: size,
        color: color,
      );
    }
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="none" '
      'stroke="$hex" stroke-width="14" stroke-linecap="round" stroke-linejoin="round">'
      '<path d="M48 88V64a16 16 0 0 1 16-16h24M168 48h24a16 16 0 0 1 16 16v24M208 168v24a16 16 0 0 1-16 16h-24M88 208H64a16 16 0 0 1-16-16v-24"/>'
      '<path d="M96 100v16M160 100v16M128 100v36h-8M96 164s12 14 32 14 32-14 32-14"/></svg>',
      width: size,
      height: size,
    );
  }
}
