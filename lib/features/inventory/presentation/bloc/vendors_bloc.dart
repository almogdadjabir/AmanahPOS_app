import 'dart:async';

import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/catalog_refresh.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'vendors_event.dart';
part 'vendors_state.dart';

/// Vendors sheet. Phase 3: reads SQLite only (active vendors) and re-reads
/// on [watchedTables]; writes go through [InventoryUseCase] ->
/// `VendorService` (row + outbox, works offline). No REST call.
class VendorsBloc extends Bloc<VendorsEvent, VendorsState> {
  final InventoryUseCase useCase;
  final OfflineLocalCache offlineLocalCache;

  /// `DbChangeNotifier.changes`.
  final Stream<Set<String>>? changes;

  /// The app's sync-now (pull to refresh); null = local re-read only.
  final Future<void> Function()? syncNow;

  static const Set<String> watchedTables = {'vendors', SyncTables.outbox};

  StreamSubscription<Set<String>>? _changesSub;
  Timer? _debounce;
  int _loadToken = 0;

  VendorsBloc({
    required this.useCase,
    required this.offlineLocalCache,
    this.changes,
    this.syncNow,
  }) : super(VendorsState.initial()) {
    on<OnVendorsStarted>(_onStarted);
    on<OnVendorsSyncRequested>((_, _) => requestCatalogSync(syncNow));
    on<OnVendorsChanged>(_onChanged);
    on<OnVendorCreate>(_onCreate);
    on<OnVendorUpdate>(_onUpdate);
    on<OnVendorDelete>(_onDelete);
    on<OnVendorsReset>(_onReset);
  }

  void _watch() {
    if (_changesSub != null || changes == null) return;
    _changesSub = changes!.listen((tables) {
      if (tables.intersection(watchedTables).isEmpty) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 16), () {
        if (!isClosed) add(const OnVendorsChanged());
      });
    });
  }

  Future<bool> _reloadOnce(Emitter<VendorsState> emit) async {
    final token = ++_loadToken;
    final vendors = await offlineLocalCache.getVendors();
    final marks = await offlineLocalCache.getCatalogSyncMarks('vendor');
    if (token != _loadToken || emit.isDone) return false;
    emit(
      state.copyWith(
        status: VendorsStatus.success,
        vendors: vendors,
        syncMarks: marks,
        clearResponseError: true,
      ),
    );
    return true;
  }

  Future<void> _reload(Emitter<VendorsState> emit) async {
    try {
      for (var i = 0; i < 4; i++) {
        if (await _reloadOnce(emit) || emit.isDone) return;
      }
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: state.vendors.isEmpty
              ? VendorsStatus.failure
              : VendorsStatus.success,
          responseError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _onStarted(
    OnVendorsStarted event,
    Emitter<VendorsState> emit,
  ) async {
    _watch();
    if (state.status == VendorsStatus.initial) {
      emit(state.copyWith(status: VendorsStatus.loading));
    }
    await _reload(emit);
  }

  Future<void> _onChanged(
    OnVendorsChanged event,
    Emitter<VendorsState> emit,
  ) async {
    if (state.status == VendorsStatus.initial) return;
    await _reload(emit);
  }

  Future<void> _submit(
    Emitter<VendorsState> emit,
    Future<String?> Function() write,
  ) async {
    if (state.submitStatus == VendorsSubmitStatus.loading) return;
    emit(
      state.copyWith(
        submitStatus: VendorsSubmitStatus.loading,
        clearSubmitError: true,
      ),
    );
    String? error;
    try {
      error = await write();
    } catch (e) {
      error = friendlyError(e);
    }
    if (emit.isDone) return;
    if (error != null) {
      emit(
        state.copyWith(
          submitStatus: VendorsSubmitStatus.failure,
          submitError: error,
        ),
      );
      return;
    }
    await _reload(emit);
    if (emit.isDone) return;
    emit(state.copyWith(submitStatus: VendorsSubmitStatus.success));
  }

  Future<void> _onCreate(OnVendorCreate event, Emitter<VendorsState> emit) =>
      _submit(emit, () async {
        final r = await useCase.createVendor(event.request);
        return r.fold((e) => e ?? '', (_) => null);
      });

  Future<void> _onUpdate(OnVendorUpdate event, Emitter<VendorsState> emit) =>
      _submit(emit, () async {
        final r = await useCase.updateVendor(event.id, event.request);
        return r.fold((e) => e ?? '', (_) => null);
      });

  Future<void> _onDelete(OnVendorDelete event, Emitter<VendorsState> emit) =>
      _submit(emit, () async {
        final r = await useCase.deleteVendor(event.id);
        return r.fold((e) => e ?? '', (_) => null);
      });

  void _onReset(OnVendorsReset event, Emitter<VendorsState> emit) {
    _loadToken++;
    emit(VendorsState.initial());
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _changesSub?.cancel();
    return super.close();
  }
}
