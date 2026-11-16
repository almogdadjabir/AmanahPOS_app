import 'dart:async';

import 'contract/sync_contract.dart';
import 'transport/sync_transport.dart';

/// "Does my server answer?" signal, backed by `sync/ping` (not connectivity).
///
/// Clock skew is informational only: the sync engine must not use it to
/// reorder or reject mutations.
class ServerReachability {
  ServerReachability(
    this._transport, {
    this.ttl = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SyncTransport _transport;
  final Duration ttl;
  final DateTime Function() _now;

  final _changes = StreamController<bool>.broadcast();
  bool _reachable = false;
  PingResponse? _lastPing;
  Duration? _clockSkew;
  DateTime? _checkedAt;
  Future<PingResponse?>? _inFlight;

  bool get isReachable => _reachable;
  Stream<bool> get changes => _changes.stream;
  PingResponse? get lastPing => _lastPing;

  /// serverTime - deviceTime at the ping round-trip midpoint.
  Duration? get clockSkew => _clockSkew;

  void _set(bool v) {
    if (_reachable == v) return;
    _reachable = v;
    if (!_changes.isClosed) _changes.add(v);
  }

  /// Closes the [changes] stream. Safe to call more than once.
  Future<void> dispose() async {
    if (!_changes.isClosed) await _changes.close();
  }

  void reportSuccess() => _set(true);

  void reportFailure() {
    _checkedAt = null; // next check() must really ping
    _set(false);
  }

  Future<PingResponse?> check({bool force = false}) {
    final at = _checkedAt;
    if (!force && at != null && _now().difference(at) < ttl) {
      return Future.value(_reachable ? _lastPing : null);
    }
    return _inFlight ??= _ping().whenComplete(() => _inFlight = null);
  }

  Future<PingResponse?> _ping() async {
    final start = _now();
    try {
      final res = await _transport.ping();
      final end = _now();
      final mid = start.add(end.difference(start) ~/ 2);
      _lastPing = res;
      _clockSkew = res.serverTime.difference(mid);
      _checkedAt = end;
      _set(res.ok);
      return res.ok ? res : null;
    } catch (_) {
      _checkedAt = _now();
      _set(false);
      return null;
    }
  }
}
