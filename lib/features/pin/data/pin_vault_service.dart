import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';

class PinVaultService {
  PinVaultService(this._cache);

  final CacheStorage _cache;
  static const _key = 'pin_vault';
  static const _escalation = [30, 60, 120, 300];

  Future<Map<String, dynamic>> _read() async {
    final raw = await _cache.getObject(_key);
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'version': 1, 'lockedUntil': null, 'failedAttempts': 0, 'users': []};
  }

  Future<void> _write(Map<String, dynamic> vault) async {
    await _cache.saveObject(_key, vault);
  }

  List<PinUserRecord> _users(Map<String, dynamic> vault) =>
      ((vault['users'] as List?) ?? const [])
          .map((e) => PinUserRecord.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  Future<bool> hasAnyEnrolled() async => _users(await _read()).isNotEmpty;

  Future<bool> isUserEnrolled(String userId) async =>
      _users(await _read()).any((u) => u.userId == userId);

  Future<bool> isPinTaken(String pin) async {
    for (final u in _users(await _read())) {
      if (PinHasher.hashPin(pin, u.pinSalt) == u.pinHash) return true;
    }
    return false;
  }

  Future<void> enrollUser(PinUserRecord record) async {
    final vault = await _read();
    final users = _users(vault)..removeWhere((u) => u.userId == record.userId);
    users.add(record);
    vault['users'] = users.map((u) => u.toJson()).toList();
    await _write(vault);
  }

  Future<PinUserRecord?> findUserByPin(String pin) async {
    final vault = await _read();
    final users = _users(vault);
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      if (PinHasher.hashPin(pin, u.pinSalt) == u.pinHash) {
        final updated = u.copyWith(lastUnlockAt: DateTime.now().toIso8601String());
        users[i] = updated;
        vault['users'] = users.map((e) => e.toJson()).toList();
        vault['failedAttempts'] = 0;
        vault['lockedUntil'] = null;
        await _write(vault);
        return updated;
      }
    }
    return null;
  }

  Future<void> recordFailedAttempt() async {
    final vault = await _read();
    final attempts = ((vault['failedAttempts'] as int?) ?? 0) + 1;
    vault['failedAttempts'] = attempts;
    if (attempts % 5 == 0) {
      final idx = (attempts ~/ 5) - 1;
      final secs = _escalation[idx.clamp(0, _escalation.length - 1)];
      vault['lockedUntil'] =
          DateTime.now().add(Duration(seconds: secs)).toIso8601String();
    }
    await _write(vault);
  }

  Future<void> clearAttempts() async {
    final vault = await _read();
    vault['failedAttempts'] = 0;
    vault['lockedUntil'] = null;
    await _write(vault);
  }

  Future<Duration> lockoutRemaining() async {
    final vault = await _read();
    final iso = vault['lockedUntil'] as String?;
    if (iso == null) return Duration.zero;
    final until = DateTime.tryParse(iso);
    if (until == null) return Duration.zero;
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> removeUser(String userId) async {
    final vault = await _read();
    final users = _users(vault)..removeWhere((u) => u.userId == userId);
    vault['users'] = users.map((u) => u.toJson()).toList();
    await _write(vault);
  }

  Future<void> clearVault() async {
    await _cache.saveObject(_key, null);
  }
}
