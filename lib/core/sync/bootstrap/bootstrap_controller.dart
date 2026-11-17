import '../sync_state_store.dart';
import 'bootstrapper.dart';

/// What the first-setup UI (Task 11) needs, without touching the engine:
/// the bootstrap progress stream, whether the CURRENT scope finished its
/// first setup, and a retry that goes through the triggers (so it never runs
/// beside the engine).
class BootstrapController {
  BootstrapController({
    required Bootstrapper bootstrapper,
    required SyncStateStore state,
    required String? Function() scopeProvider,
    Future<Object?> Function()? retry,
  }) : _bootstrapper = bootstrapper,
       _state = state,
       _scope = scopeProvider,
       _retry = retry;

  final Bootstrapper _bootstrapper;
  final SyncStateStore _state;
  final String? Function() _scope;
  final Future<Object?> Function()? _retry;

  Stream<BootstrapStatus> get status => _bootstrapper.status;

  /// The live session scope (`userId|tenantId`), to drop statuses of
  /// another scope ([BootstrapStatus.scope]).
  String? get liveScope => _scope();
  BootstrapStatus get current => _bootstrapper.current;

  /// First-setup UI gate (ruling T11-a): true when any user of the live
  /// scope's TENANT finished first setup on this device (shared catalog
  /// tables), so a shift change without internet never stops sales. This
  /// scope's own bootstrap still runs (non-blocking) when online.
  Future<bool> isTenantBootstrapped() async {
    final scope = _scope();
    if (scope == null) return false;
    final parts = scope.split('|');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return false;
    }
    return _state.isTenantBootstrapped(parts[1]);
  }

  /// Manual retry (the only way to retry a `blocked` first setup). Returns
  /// the run's outcome; null when no run started (not signed in, or the sync
  /// gate refused: server unreachable or without the sync capabilities).
  Future<Object?> retry() async => _retry?.call();
}
