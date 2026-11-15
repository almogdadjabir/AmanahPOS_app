import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind { face, fingerprint, other }

/// Face ID / fingerprint unlock on top of the PIN. The PIN stays the
/// fallback and the thing that enrols a person. Biometric unlock is offered
/// only when exactly one person is enrolled on the device and they opted in:
/// the device biometric proves who owns the phone, not which cashier is
/// holding a shared one.
class BiometricUnlockService {
  BiometricUnlockService({
    required CacheStorage cache,
    required PinVaultService vault,
    LocalAuthentication? auth,
  }) : _cache = cache,
       _vault = vault,
       _auth = auth ?? LocalAuthentication();

  final CacheStorage _cache;
  final PinVaultService _vault;
  final LocalAuthentication _auth;

  static const _enabledKey = 'biometric_unlock_user';

  /// The kind of biometric this device has enrolled, or null when none.
  Future<BiometricKind?> availableKind() async {
    try {
      if (!await _auth.isDeviceSupported()) return null;
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return null;
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      return BiometricKind.other;
    } on PlatformException {
      return null;
    }
  }

  /// Asks the OS to confirm the person. False on cancel, failure or error.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }

  /// The one enrolled person who turned biometric unlock on, if it applies.
  Future<PinUserRecord?> eligibleUser() async {
    final users = await _vault.allUsers();
    if (users.length != 1) return null;
    final enabledFor = await _cache.read(_enabledKey);
    if (enabledFor != users.first.userId) return null;
    if (await availableKind() == null) return null;
    return users.first;
  }

  /// The one enrolled person, when this device has a biometric to offer.
  /// The Face ID key shows for them even before they have turned it on.
  Future<PinUserRecord?> offeredUser() async {
    final users = await _vault.allUsers();
    if (users.length != 1) return null;
    if (await availableKind() == null) return null;
    return users.first;
  }

  Future<bool> isEnabledFor(String userId) async =>
      await _cache.read(_enabledKey) == userId;

  /// Whether to offer turning it on: a biometric exists, and this person is
  /// the only one enrolled and hasn't enabled it yet.
  Future<BiometricKind?> offerFor(String userId) async {
    final users = await _vault.allUsers();
    if (users.length != 1 || users.first.userId != userId) return null;
    if (await _cache.read(_enabledKey) == userId) return null;
    return availableKind();
  }

  /// Confirms with the OS once, then remembers the choice.
  Future<bool> enable(String userId, String reason) async {
    if (!await authenticate(reason)) return false;
    await _cache.save(_enabledKey, userId);
    return true;
  }

  Future<void> disable() => _cache.save(_enabledKey, null);
}
