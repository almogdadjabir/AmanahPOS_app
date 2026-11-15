part of 'pin_bloc.dart';

sealed class PinEvent {
  const PinEvent();
}

class PinDigitPressed extends PinEvent {
  final String digit;
  const PinDigitPressed(this.digit);
}

class PinBackspace extends PinEvent {
  const PinBackspace();
}

class PinCleared extends PinEvent {
  const PinCleared();
}

class PinLockoutTicked extends PinEvent {
  const PinLockoutTicked();
}

/// The device biometric confirmed the person; unlock [userId] without a PIN.
class PinBiometricUnlocked extends PinEvent {
  final String userId;
  const PinBiometricUnlocked(this.userId);
}
