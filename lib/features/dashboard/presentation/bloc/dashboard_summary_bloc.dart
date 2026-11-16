import 'dart:async';

import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_summary_event.dart';
part 'dashboard_summary_state.dart';

class DashboardSummaryBloc
    extends Bloc<DashboardSummaryEvent, DashboardSummaryState> {
  final GetDashboardSummaryUseCase getDashboardSummaryUseCase;

  static const Duration _freshDuration = Duration(seconds: 45);

  String? _activeRequestKey;
  String? _lastSuccessRequestKey;
  DateTime? _lastSuccessAt;

  int _requestVersion = 0;

  /// Local-first mode (sync engine on): the summary comes from a reactive
  /// SQLite stream. Data is emitted as it arrives, never behind a loading
  /// or refreshing state.
  StreamSubscription<DashboardSummary>? _localSub;
  String? _localKey;
  String? _localParams;
  int _localGeneration = 0;

  DashboardSummaryBloc({required this.getDashboardSummaryUseCase})
    : super(const DashboardSummaryState()) {
    on<OnDashboardSummaryStarted>(_onStarted);
    on<OnDashboardSummaryRefreshRequested>(_onRefreshRequested);
    on<OnDashboardSummaryShopChanged>(_onShopChanged);
    on<OnDashboardSummaryReset>(_onReset);
    on<_DashboardLocalSummaryReceived>(_onLocalReceived);
    on<_DashboardLocalSummaryFailed>(_onLocalFailed);
  }

  @override
  Future<void> close() async {
    await _localSub?.cancel();
    return super.close();
  }

  /// Subscribes to the local summary stream when the repository offers one.
  /// Returns false when the dashboard uses the REST path. [restart] re-reads
  /// "today" (refresh); otherwise an identical live subscription is kept.
  bool _watchLocal({
    required String? businessId,
    required String? shopId,
    required String? timezone,
    required int topSellersLimit,
    required bool restart,
  }) {
    final key = [
      businessId ?? 'default_business',
      shopId ?? 'all_shops',
      timezone ?? 'default_timezone',
      topSellersLimit,
    ].join('|');
    if (!restart && _localSub != null && _localParams == key) return true;

    final stream = getDashboardSummaryUseCase.watch(
      businessId: businessId,
      shopId: shopId,
      timezone: timezone,
      topSellersLimit: topSellersLimit,
    );
    if (stream == null) return false;

    _requestVersion++; // drop any in-flight REST response
    _activeRequestKey = null;
    _localSub?.cancel();
    _localParams = key;
    // Unique per subscription: values still queued from a replaced
    // subscription (same params on refresh) are dropped.
    final subKey = '$key#${++_localGeneration}';
    _localKey = subKey;
    _localSub = stream.listen(
      (summary) => add(
        _DashboardLocalSummaryReceived(
          summary: summary,
          key: subKey,
          businessId: businessId,
          shopId: shopId,
          timezone: timezone,
          topSellersLimit: topSellersLimit,
        ),
      ),
      onError: (Object e) =>
          add(_DashboardLocalSummaryFailed(message: e.toString(), key: subKey)),
    );
    return true;
  }

  void _onLocalReceived(
    _DashboardLocalSummaryReceived event,
    Emitter<DashboardSummaryState> emit,
  ) {
    if (event.key != _localKey) return; // stale subscription
    emit(
      state.copyWith(
        status: DashboardSummaryStatus.success,
        summary: event.summary,
        businessId: event.businessId,
        shopId: event.shopId,
        timezone: event.timezone,
        topSellersLimit: event.topSellersLimit,
        errorMessage: null,
      ),
    );
  }

  void _onLocalFailed(
    _DashboardLocalSummaryFailed event,
    Emitter<DashboardSummaryState> emit,
  ) {
    if (event.key != _localKey) return;
    debugPrint('[DashboardBloc] local summary failed: ${event.message}');
    emit(
      state.copyWith(
        status: DashboardSummaryStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onStarted(
    OnDashboardSummaryStarted event,
    Emitter<DashboardSummaryState> emit,
  ) async {
    if (_watchLocal(
      businessId: event.businessId,
      shopId: event.shopId,
      timezone: event.timezone,
      topSellersLimit: event.topSellersLimit,
      restart: event.forceRefresh,
    )) {
      return;
    }

    final requestKey = _requestKey(
      businessId: event.businessId,
      shopId: event.shopId,
      date: event.date,
      timezone: event.timezone,
      topSellersLimit: event.topSellersLimit,
    );

    if (!event.forceRefresh && _shouldSkipRequest(requestKey)) {
      debugPrint('[DashboardBloc] skip fresh request: $requestKey');
      return;
    }

    if (_isSameRequestLoading(requestKey)) {
      debugPrint('[DashboardBloc] skip duplicate loading request: $requestKey');
      return;
    }

    final version = ++_requestVersion;
    _activeRequestKey = requestKey;

    debugPrint('[DashboardBloc] started v$version: $requestKey');

    emit(
      state.copyWith(
        status: state.summary == null
            ? DashboardSummaryStatus.loading
            : DashboardSummaryStatus.refreshing,
        businessId: event.businessId,
        shopId: event.shopId,
        date: event.date,
        timezone: event.timezone,
        topSellersLimit: event.topSellersLimit,
        errorMessage: null,
      ),
    );

    await _load(
      emit: emit,
      version: version,
      requestKey: requestKey,
      businessId: event.businessId,
      shopId: event.shopId,
      date: event.date,
      timezone: event.timezone,
      topSellersLimit: event.topSellersLimit,
      forceRefresh: event.forceRefresh,
    );
  }

  Future<void> _onRefreshRequested(
    OnDashboardSummaryRefreshRequested event,
    Emitter<DashboardSummaryState> emit,
  ) async {
    final businessId = event.businessId ?? state.businessId;
    final shopId = event.shopId ?? state.shopId;
    final date = event.date ?? state.date;
    final timezone = event.timezone ?? state.timezone;
    final topSellersLimit = event.topSellersLimit ?? state.topSellersLimit;

    if (_watchLocal(
      businessId: businessId,
      shopId: shopId,
      timezone: timezone,
      topSellersLimit: topSellersLimit,
      restart: true,
    )) {
      return;
    }

    final requestKey = _requestKey(
      businessId: businessId,
      shopId: shopId,
      date: date,
      timezone: timezone,
      topSellersLimit: topSellersLimit,
    );

    if (_isSameRequestLoading(requestKey)) {
      debugPrint('[DashboardBloc] skip duplicate refresh: $requestKey');
      return;
    }

    final version = ++_requestVersion;
    _activeRequestKey = requestKey;

    debugPrint('[DashboardBloc] refresh v$version: $requestKey');

    emit(
      state.copyWith(
        status: state.summary == null
            ? DashboardSummaryStatus.loading
            : DashboardSummaryStatus.refreshing,
        businessId: businessId,
        shopId: shopId,
        date: date,
        timezone: timezone,
        topSellersLimit: topSellersLimit,
        errorMessage: null,
      ),
    );

    await _load(
      emit: emit,
      version: version,
      requestKey: requestKey,
      businessId: businessId,
      shopId: shopId,
      date: date,
      timezone: timezone,
      topSellersLimit: topSellersLimit,
      forceRefresh: true,
    );
  }

  Future<void> _onShopChanged(
    OnDashboardSummaryShopChanged event,
    Emitter<DashboardSummaryState> emit,
  ) async {
    if (_watchLocal(
      businessId: state.businessId,
      shopId: event.shopId,
      timezone: state.timezone,
      topSellersLimit: state.topSellersLimit,
      restart: false,
    )) {
      return;
    }

    final requestKey = _requestKey(
      businessId: state.businessId,
      shopId: event.shopId,
      date: state.date,
      timezone: state.timezone,
      topSellersLimit: state.topSellersLimit,
    );

    if (_shouldSkipRequest(requestKey)) {
      emit(state.copyWith(shopId: event.shopId));
      debugPrint('[DashboardBloc] skip shop fresh request: $requestKey');
      return;
    }

    if (_isSameRequestLoading(requestKey)) {
      debugPrint('[DashboardBloc] skip duplicate shop request: $requestKey');
      return;
    }

    final version = ++_requestVersion;
    _activeRequestKey = requestKey;

    debugPrint('[DashboardBloc] shop changed v$version: $requestKey');

    emit(
      state.copyWith(
        status: state.summary == null
            ? DashboardSummaryStatus.loading
            : DashboardSummaryStatus.refreshing,
        shopId: event.shopId,
        errorMessage: null,
      ),
    );

    await _load(
      emit: emit,
      version: version,
      requestKey: requestKey,
      businessId: state.businessId,
      shopId: event.shopId,
      date: state.date,
      timezone: state.timezone,
      topSellersLimit: state.topSellersLimit,
      forceRefresh: false,
    );
  }

  void _onReset(
    OnDashboardSummaryReset event,
    Emitter<DashboardSummaryState> emit,
  ) {
    _requestVersion++;
    _localSub?.cancel();
    _localSub = null;
    _localKey = null;
    _localParams = null;
    _activeRequestKey = null;
    _lastSuccessRequestKey = null;
    _lastSuccessAt = null;
    emit(const DashboardSummaryState());
  }

  Future<void> _load({
    required Emitter<DashboardSummaryState> emit,
    required int version,
    required String requestKey,
    required String? businessId,
    required String? shopId,
    required DateTime? date,
    required String? timezone,
    required int topSellersLimit,
    required bool forceRefresh,
  }) async {
    try {
      final summary = await getDashboardSummaryUseCase(
        businessId: businessId,
        shopId: shopId,
        date: date,
        timezone: timezone,
        topSellersLimit: topSellersLimit,
        forceRefresh: forceRefresh,
      );

      if (version != _requestVersion) {
        debugPrint(
          '[DashboardBloc] ignored stale response v$version. '
          'latest=$_requestVersion key=$requestKey total=${summary.today.grossSalesAmount}',
        );
        return;
      }

      _activeRequestKey = null;
      _lastSuccessRequestKey = requestKey;
      _lastSuccessAt = DateTime.now();

      debugPrint(
        '[DashboardBloc] emit v$version key=$requestKey '
        'total=${summary.today.grossSalesAmount} '
        'source=${summary.source} '
        'pending=${summary.includesLocalPendingSales}',
      );

      emit(
        state.copyWith(
          status: DashboardSummaryStatus.success,
          summary: summary,
          businessId: businessId,
          shopId: shopId,
          date: date,
          timezone: timezone,
          topSellersLimit: topSellersLimit,
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (version != _requestVersion) {
        debugPrint('[DashboardBloc] ignored stale error v$version: $e');
        return;
      }

      _activeRequestKey = null;

      emit(
        state.copyWith(
          status: DashboardSummaryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  bool _shouldSkipRequest(String requestKey) {
    if (state.summary == null) return false;
    if (_lastSuccessRequestKey != requestKey) return false;
    if (_lastSuccessAt == null) return false;

    final age = DateTime.now().difference(_lastSuccessAt!);
    return age <= _freshDuration;
  }

  bool _isSameRequestLoading(String requestKey) {
    final isLoading =
        state.status == DashboardSummaryStatus.loading ||
        state.status == DashboardSummaryStatus.refreshing;

    return isLoading && _activeRequestKey == requestKey;
  }

  String _requestKey({
    required String? businessId,
    required String? shopId,
    required DateTime? date,
    required String? timezone,
    required int topSellersLimit,
  }) {
    final resolvedDate = _formatDate(date ?? DateTime.now());

    return [
      businessId ?? 'default_business',
      shopId ?? 'all_shops',
      resolvedDate,
      timezone ?? 'default_timezone',
      topSellersLimit,
    ].join('|');
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
