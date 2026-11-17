import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/sync_engine.dart' show SyncBlockReason;
import 'package:equatable/equatable.dart';

/// Where the signed-in scope stands with its first setup (spec 2026-11-16
/// phase 2, sections 2 and 5).
///
///  * [checking]: not evaluated yet (no session / before the first check).
///    Never blocks.
///  * [required]: never bootstrapped; the run has not started (or stopped
///    for a transient reason and will be retried). Blocks.
///  * [running]: first setup in progress. Blocks.
///  * [blockedOffline]: never bootstrapped and no connection. Blocks.
///  * [blockedServer]: never bootstrapped and the server cannot serve a
///    paged bootstrap (`bootstrap_paged` missing). Blocks.
///  * [blockedAccount]: never bootstrapped and the run was refused for the
///    session/account ([FirstSetupStatus.blockReason]: token expired,
///    account disabled, device revoked, no session). Retrying cannot help;
///    the screen says why and offers sign-out. Blocks.
///  * [done]: the scope is bootstrapped. Never blocks, also while a later
///    refresh (`full_resync_required`) re-downloads in the background.
enum FirstSetupPhase {
  checking,
  required,
  running,
  blockedOffline,
  blockedServer,
  blockedAccount,
  done,
}

class FirstSetupStatus extends Equatable {
  const FirstSetupStatus._(
    this.phase, {
    this.entity,
    this.index = 0,
    this.count = 0,
    this.rowsApplied = 0,
    this.blockReason,
  });

  /// The [SyncBlockReason]s that make the first setup [blockedAccount].
  static const Set<SyncBlockReason> accountReasons = {
    SyncBlockReason.tokenExpired,
    SyncBlockReason.accountDisabled,
    SyncBlockReason.deviceRevoked,
    SyncBlockReason.noSession,
  };

  const FirstSetupStatus.checking() : this._(FirstSetupPhase.checking);

  const FirstSetupStatus.required() : this._(FirstSetupPhase.required);

  const FirstSetupStatus.running({
    required String? entity,
    required int index,
    required int count,
    required int rowsApplied,
  }) : this._(
         FirstSetupPhase.running,
         entity: entity,
         index: index,
         count: count,
         rowsApplied: rowsApplied,
       );

  const FirstSetupStatus.blockedOffline()
    : this._(FirstSetupPhase.blockedOffline);

  const FirstSetupStatus.blockedServer()
    : this._(FirstSetupPhase.blockedServer);

  const FirstSetupStatus.blockedAccount(SyncBlockReason reason)
    : this._(FirstSetupPhase.blockedAccount, blockReason: reason);

  const FirstSetupStatus.done() : this._(FirstSetupPhase.done);

  final FirstSetupPhase phase;

  /// Running only: the entity being downloaded (feed name, e.g. `product`).
  final String? entity;

  /// Running only: 0-based position of [entity] in this run's entity list.
  final int index;

  /// Running only: number of entities this scope downloads.
  final int count;

  /// Running only: rows written by this run so far.
  final int rowsApplied;

  /// [FirstSetupPhase.blockedAccount] only: why the run was refused.
  final SyncBlockReason? blockReason;

  /// The app must not be used (POS hidden behind the first-setup screen).
  bool get blocksApp =>
      phase != FirstSetupPhase.done && phase != FirstSetupPhase.checking;

  bool get isRunning => phase == FirstSetupPhase.running;

  /// Pure readiness rule. [bootstrapped] is the scope's `bootstrapped` flag
  /// (the ONLY thing that unblocks the app). [offline] is the device's
  /// connectivity. [boot] is the bootstrapper's latest status (any scope run
  /// of this process; null when none). [gateRefused] means a manual retry
  /// was not even started (server lacks the sync capabilities / no token).
  static FirstSetupStatus derive({
    required bool bootstrapped,
    required bool offline,
    BootstrapStatus? boot,
    bool gateRefused = false,
  }) {
    if (bootstrapped) return const FirstSetupStatus.done();
    if (boot != null && isBootRunning(boot)) {
      return FirstSetupStatus.running(
        entity: boot.currentEntity,
        index: boot.entityIndex,
        count: boot.entityCount,
        rowsApplied: boot.rowsApplied,
      );
    }
    if (offline) return const FirstSetupStatus.blockedOffline();
    if (boot != null && boot.serverNotReady) {
      return const FirstSetupStatus.blockedServer();
    }
    final block = boot?.block;
    if (boot != null &&
        boot.outcome == BootstrapOutcome.blocked &&
        block != null &&
        accountReasons.contains(block)) {
      return FirstSetupStatus.blockedAccount(block);
    }
    if (boot != null &&
        boot.outcome == BootstrapOutcome.interrupted &&
        boot.offline) {
      return const FirstSetupStatus.blockedOffline();
    }
    if (gateRefused) return const FirstSetupStatus.blockedServer();
    return const FirstSetupStatus.required();
  }

  /// A run is in flight and has reached its entity list.
  static bool isBootRunning(BootstrapStatus s) =>
      s.outcome == null && (s.currentEntity != null || s.entityCount > 0);

  @override
  List<Object?> get props => [
    phase,
    entity,
    index,
    count,
    rowsApplied,
    blockReason,
  ];

  @override
  String toString() => phase == FirstSetupPhase.running
      ? 'FirstSetupStatus.running($entity ${index + 1}/$count, '
            'rows=$rowsApplied)'
      : phase == FirstSetupPhase.blockedAccount
      ? 'FirstSetupStatus.blockedAccount(${blockReason?.name})'
      : 'FirstSetupStatus.${phase.name}';
}
