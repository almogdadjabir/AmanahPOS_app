part of 'pin_bloc.dart';

enum PinMode { setup, unlock, change }

enum PinPhase { entering, confirming, success, mismatch, error, locked }

class PinState {
  final String entered;
  final String firstEntry;
  final PinMode mode;
  final PinPhase phase;
  final Duration lockoutRemaining;
  final String? errorText;
  final PinUserRecord? unlockedUser;
  final bool currentVerified;

  const PinState({
    required this.entered,
    required this.firstEntry,
    required this.mode,
    required this.phase,
    required this.lockoutRemaining,
    this.errorText,
    this.unlockedUser,
    this.currentVerified = false,
  });

  factory PinState.initial(PinMode mode) => PinState(
        entered: '', firstEntry: '', mode: mode,
        phase: PinPhase.entering, lockoutRemaining: Duration.zero,
        currentVerified: false,
      );

  PinState copyWith({
    String? entered,
    String? firstEntry,
    PinPhase? phase,
    Duration? lockoutRemaining,
    String? errorText,
    bool clearError = false,
    PinUserRecord? unlockedUser,
    bool? currentVerified,
  }) =>
      PinState(
        entered: entered ?? this.entered,
        firstEntry: firstEntry ?? this.firstEntry,
        mode: mode,
        phase: phase ?? this.phase,
        lockoutRemaining: lockoutRemaining ?? this.lockoutRemaining,
        errorText: clearError ? null : (errorText ?? this.errorText),
        unlockedUser: unlockedUser ?? this.unlockedUser,
        currentVerified: currentVerified ?? this.currentVerified,
      );
}
