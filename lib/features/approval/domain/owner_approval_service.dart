import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';

sealed class ApprovalResult {
  const ApprovalResult();
}

class Approved extends ApprovalResult {
  const Approved();
}

class WrongPin extends ApprovalResult {
  const WrongPin(this.triesLeft);
  final int triesLeft;
}

class Locked extends ApprovalResult {
  const Locked(this.seconds);
  final int seconds;
}

/// No owner has a PIN saved on this phone.
class NoOwnerPin extends ApprovalResult {
  const NoOwnerPin();
}

/// Checks a PIN against the owner PINs saved on this phone (works offline).
/// Five wrong tries lock approval for 30 seconds; the counter lives in
/// memory only. Does not touch the sign-in lock or the vault's bookkeeping.
class OwnerApprovalService {
  OwnerApprovalService(this._vault, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PinVaultService _vault;
  final DateTime Function() _now;

  static const int maxTries = 5;
  static const Duration lockFor = Duration(seconds: 30);

  int _wrong = 0;
  DateTime? _lockedUntil;

  Future<ApprovalResult> check(String pin) async {
    final until = _lockedUntil;
    if (until != null) {
      final left = until.difference(_now());
      if (!left.isNegative && left > Duration.zero) {
        return Locked((left.inMilliseconds / 1000).ceil());
      }
      _lockedUntil = null;
      _wrong = 0;
    }
    final owners = [
      for (final u in await _vault.allUsers())
        if (u.role.toLowerCase() == 'owner') u,
    ];
    if (owners.isEmpty) return const NoOwnerPin();
    for (final o in owners) {
      if (PinHasher.hashPin(pin, o.pinSalt) == o.pinHash) {
        _wrong = 0;
        return const Approved();
      }
    }
    _wrong++;
    if (_wrong >= maxTries) {
      _lockedUntil = _now().add(lockFor);
      _wrong = 0;
      return Locked(lockFor.inSeconds);
    }
    return WrongPin(maxTries - _wrong);
  }

  /// Whether any owner PIN is saved here, to tell the user before asking.
  Future<bool> hasOwnerPin() async => [
    for (final u in await _vault.allUsers())
      if (u.role.toLowerCase() == 'owner') u,
  ].isNotEmpty;
}
