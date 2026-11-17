import 'dart:async';
import 'dart:developer' as developer;

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/presentation/bloc/first_setup_status.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrap_controller.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:amana_pos/core/offline/presentation/bloc/first_setup_status.dart';

part 'offline_status_event.dart';
part 'offline_status_state.dart';

/// Connectivity, unsynced count and app READINESS.
///
/// Readiness (spec 2026-11-16 phase 2, sections 2 and 5) comes from the sync
/// core only: the signed-in scope's `bootstrapped` flag plus the
/// bootstrapper's progress ([BootstrapController]); there is no other
/// data path (the legacy bulk bootstrap is retired).
/// `hasCache` / `canUseAppOffline` are true iff a scope of the signed-in
/// TENANT is bootstrapped on this device (ruling T11-a: catalog tables are
/// shared by the tenant's users). A later refresh (`full_resync_required`)
/// or this user's own first bootstrap after another user of the tenant set
/// the device up never blocks and only sets
/// [OfflineStatusState.setupRefreshing].
class OfflineStatusBloc extends Bloc<OfflineStatusEvent, OfflineStatusState> {
  final NetworkMonitor networkMonitor;

  /// Unsynced outbox rows (all scopes, rejected included). The sync engine
  /// pushes them; this bloc only counts them (display + logout gate).
  final Future<int> Function() outboxUnsyncedCount;

  /// First-setup source; null = sync core disabled (kill switch): readiness
  /// is then never blocking.
  final Future<BootstrapController?> Function()? firstSetup;

  int _logoutVersion = 0;

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<BootstrapStatus>? _setupSubscription;
  BootstrapController? _setup;

  /// Between [OnOfflineStatusStarted] and [OnOfflineStatusResetRequested].
  bool _started = false;
  bool _bootstrapped = false;
  BootstrapStatus? _boot;

  /// Bumped (synchronously, in the stream listener) for every run outcome.
  int _outcomeSeq = 0;

  /// The last manual retry did not start any run (sync gate refused).
  bool _gateRefused = false;

  OfflineStatusBloc({
    required this.networkMonitor,
    required this.outboxUnsyncedCount,
    this.firstSetup,
  }) : super(OfflineStatusState.initial()) {
    on<OnOfflineStatusStarted>(_onStarted);
    on<OnOfflineStatusRefreshRequested>(_onRefreshRequested);
    on<OnOfflineStatusSyncSalesRequested>(_onSyncSalesRequested);
    on<OnOfflineConnectionChanged>(_onConnectionChanged);
    on<OnOfflinePendingSalesCountChanged>(_onPendingSalesCountChanged);
    on<OnOfflineStatusResetRequested>(_onResetRequested);
    on<_OnFirstSetupProgress>(_onFirstSetupProgress);
  }

  Future<void> _onStarted(
    OnOfflineStatusStarted event,
    Emitter<OfflineStatusState> emit,
  ) async {
    final version = _logoutVersion;
    final isOnline = await networkMonitor.isOnline;
    final pendingSalesCount = await outboxUnsyncedCount();
    final setup = await _resolveSetup();
    // Subscribe BEFORE the flag read: a run that ends during the read must
    // not be lost (review M1).
    _setupSubscription ??= setup?.status.listen((s) {
      if (s.outcome != null) _outcomeSeq++;
      add(_OnFirstSetupProgress(s));
    });
    final seq = _outcomeSeq;
    var bootstrapped = await _isBootstrapped(setup);
    if (_outcomeSeq != seq) bootstrapped = await _isBootstrapped(setup);
    if (version != _logoutVersion) return; // logged out meanwhile

    _started = true;
    _bootstrapped = bootstrapped;
    // Process-wide status: only this scope's counts (review M2).
    _boot = _forLiveScope(setup?.current);

    emit(
      _withSetup(
        state.copyWith(
          pendingSalesCount: pendingSalesCount,
          connectionStatus: isOnline
              ? OfflineConnectionStatus.online
              : OfflineConnectionStatus.offline,
          clearErrorMessage: true,
        ),
      ),
    );

    _connectionSubscription ??= networkMonitor.onStatusChanged.listen((
      isOnline,
    ) {
      add(OnOfflineConnectionChanged(isOnline: isOnline));
    });

    networkMonitor.start();
  }

  Future<void> _onFirstSetupProgress(
    _OnFirstSetupProgress event,
    Emitter<OfflineStatusState> emit,
  ) async {
    if (!_started) return; // _onStarted reads current + the flag itself
    final status = _forLiveScope(event.status);
    if (status == null) return; // another (previous) scope's run
    final version = _logoutVersion;
    _boot = status;
    _gateRefused = false;
    if (event.status.outcome != null) {
      // A run ended: only the stored flag says whether the app is ready.
      final bootstrapped = await _isBootstrapped(_setup);
      if (version != _logoutVersion || !_started) return;
      _bootstrapped = bootstrapped;
    }
    emit(_withSetup(state));
  }

  /// Retry (first-setup screen / footer). Goes through the sync triggers
  /// (never beside the engine); the legacy bulk refresh is gone.
  Future<void> _onRefreshRequested(
    OnOfflineStatusRefreshRequested event,
    Emitter<OfflineStatusState> emit,
  ) async {
    final setup = _setup ?? await _resolveSetup();
    if (setup != null && !_bootstrapped) {
      _gateRefused = false;
      emit(_withSetup(state));
    }
    final version = _logoutVersion;
    Object? outcome;
    try {
      outcome = await setup?.retry();
    } catch (e, st) {
      _log('first setup retry failed', e, st);
    }
    if (version != _logoutVersion || !_started) return;
    if (setup != null) {
      _bootstrapped = await _isBootstrapped(setup);
      if (version != _logoutVersion || !_started) return;
      // No run at all although online: the server is reachable for the
      // device but the sync gate said no (no sync capabilities / no ping).
      _gateRefused = outcome == null && !_bootstrapped && state.isOnline;
    }
    final count = await outboxUnsyncedCount();
    if (version != _logoutVersion || !_started) return;
    emit(_withSetup(state.copyWith(pendingSalesCount: count)));
  }

  Future<void> _onSyncSalesRequested(
    OnOfflineStatusSyncSalesRequested event,
    Emitter<OfflineStatusState> emit,
  ) async {
    await _syncSales(emit);
  }

  Future<void> _onConnectionChanged(
    OnOfflineConnectionChanged event,
    Emitter<OfflineStatusState> emit,
  ) async {
    emit(
      state.copyWith(
        connectionStatus: event.isOnline
            ? OfflineConnectionStatus.online
            : OfflineConnectionStatus.offline,
        clearErrorMessage: true,
      ),
    );
    // The sync triggers retry the first setup on connectivity regained.
    if (_started) emit(_withSetup(state));

    if (event.isOnline) {
      unawaited(_backgroundSyncSales());
    }
  }

  void _onPendingSalesCountChanged(
    OnOfflinePendingSalesCountChanged event,
    Emitter<OfflineStatusState> emit,
  ) {
    emit(state.copyWith(pendingSalesCount: event.count));
  }

  Future<void> _syncSales(Emitter<OfflineStatusState> emit) async {
    final isOnline = await networkMonitor.isOnline;

    if (!isOnline) {
      final count = await outboxUnsyncedCount();

      emit(
        state.copyWith(
          connectionStatus: OfflineConnectionStatus.offline,
          pendingSalesCount: count,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        salesSyncStatus: OfflineSalesSyncStatus.syncing,
        clearErrorMessage: true,
      ),
    );

    try {
      // Pushing is the sync engine's job; refresh the unsynced count only.
      final count = await outboxUnsyncedCount();

      emit(
        state.copyWith(
          salesSyncStatus: OfflineSalesSyncStatus.success,
          pendingSalesCount: count,
          lastSalesSyncAt: DateTime.now(),
        ),
      );
    } catch (e) {
      final count = await outboxUnsyncedCount();

      emit(
        state.copyWith(
          salesSyncStatus: OfflineSalesSyncStatus.failure,
          pendingSalesCount: count,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _backgroundSyncSales() async {
    final version = _logoutVersion;

    try {
      final isOnline = await networkMonitor.isOnline;
      if (!isOnline) return;
      if (version != _logoutVersion) return;

      final count = await outboxUnsyncedCount();

      if (version != _logoutVersion) return;

      add(OnOfflinePendingSalesCountChanged(count: count));
    } catch (_) {
      // Silent background sync failure.
    }
  }

  Future<void> _onResetRequested(
    OnOfflineStatusResetRequested event,
    Emitter<OfflineStatusState> emit,
  ) async {
    _logoutVersion++;
    _started = false;
    _bootstrapped = false;
    _boot = null;
    _gateRefused = false;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    emit(OfflineStatusState.initial());
  }

  // ------------------------------------------------------------ first setup

  /// Applies the readiness rule to [base] and mirrors it into the legacy
  /// fields older widgets read (`hasCache`, `canUseAppOffline`,
  /// `bootstrapStatus`).
  OfflineStatusState _withSetup(OfflineStatusState base) {
    // No source (kill switch, or the sync core failed to build): there is
    // no first setup to wait for, so never block.
    final noSource = firstSetup == null || (_started && _setup == null);
    final bootstrapped = noSource || _bootstrapped;
    final setup = FirstSetupStatus.derive(
      bootstrapped: bootstrapped,
      offline: base.connectionStatus == OfflineConnectionStatus.offline,
      boot: _boot,
      gateRefused: _gateRefused,
    );
    final boot = _boot;
    final refreshing =
        bootstrapped && boot != null && FirstSetupStatus.isBootRunning(boot);
    final legacy = switch (setup.phase) {
      FirstSetupPhase.checking => OfflineBootstrapStatus.initial,
      FirstSetupPhase.required ||
      FirstSetupPhase.running => OfflineBootstrapStatus.loading,
      FirstSetupPhase.blockedOffline ||
      FirstSetupPhase.blockedServer ||
      FirstSetupPhase.blockedAccount => OfflineBootstrapStatus.failure,
      FirstSetupPhase.done =>
        refreshing
            ? OfflineBootstrapStatus.loading
            : OfflineBootstrapStatus.success,
    };
    return base.copyWith(
      setupStatus: setup,
      setupRefreshing: refreshing,
      hasCache: bootstrapped,
      canUseAppOffline: bootstrapped,
      bootstrapStatus: legacy,
    );
  }

  /// [s] when it belongs to the live session scope, else null.
  BootstrapStatus? _forLiveScope(BootstrapStatus? s) {
    if (s == null || s.scope == null) return null;
    return s.scope == _setup?.liveScope ? s : null;
  }

  Future<BootstrapController?> _resolveSetup() async {
    final provider = firstSetup;
    if (provider == null) return null;
    if (_setup != null) return _setup;
    try {
      return _setup = await provider();
    } catch (e, st) {
      _log('first setup source unavailable', e, st);
      return null;
    }
  }

  Future<bool> _isBootstrapped(BootstrapController? setup) async {
    if (setup == null) return true; // no source: never blocks
    try {
      // Ruling T11-a: any user of this tenant set the device up (shared
      // catalog tables). This scope's own bootstrap still runs, non-blocking.
      return await setup.isTenantBootstrapped();
    } catch (e, st) {
      _log('bootstrapped check failed', e, st);
      return false;
    }
  }

  void _log(String msg, Object e, StackTrace st) =>
      developer.log(msg, name: 'OfflineStatusBloc', error: e, stackTrace: st);

  Future<bool> get isDeviceOnline async {
    return networkMonitor.isOnline;
  }

  /// Total unsynced (pending + syncing + failed) — for display.
  Future<int> get pendingOfflineSalesCount async {
    return outboxUnsyncedCount();
  }

  /// Unsent work: every unsynced outbox row of any scope, rejected included.
  /// Used to gate logout.
  Future<int> get blockingPendingOfflineSalesCount => outboxUnsyncedCount();

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    await _setupSubscription?.cancel();
    return super.close();
  }
}
