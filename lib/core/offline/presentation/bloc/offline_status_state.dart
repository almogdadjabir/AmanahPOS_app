part of 'offline_status_bloc.dart';

enum OfflineConnectionStatus { unknown, online, offline }

enum OfflineBootstrapStatus { initial, loading, success, failure }

enum OfflineSalesSyncStatus { idle, syncing, success, failure }

class OfflineStatusState extends Equatable {
  final OfflineConnectionStatus connectionStatus;
  final OfflineBootstrapStatus bootstrapStatus;
  final OfflineSalesSyncStatus salesSyncStatus;
  final bool hasCache;
  final bool canUseAppOffline;
  final int pendingSalesCount;
  final DateTime? lastSalesSyncAt;

  final String? errorMessage;

  /// First-setup readiness of the signed-in scope (the ONLY gate that hides
  /// POS behind the first-setup screen).
  final FirstSetupStatus setupStatus;

  /// Bootstrapped scope re-downloading after `full_resync_required`: a small
  /// non-blocking indicator at most.
  final bool setupRefreshing;

  const OfflineStatusState({
    required this.connectionStatus,
    required this.bootstrapStatus,
    required this.salesSyncStatus,
    required this.hasCache,
    required this.canUseAppOffline,
    required this.pendingSalesCount,
    required this.lastSalesSyncAt,
    required this.errorMessage,
    this.setupStatus = const FirstSetupStatus.checking(),
    this.setupRefreshing = false,
  });

  factory OfflineStatusState.initial() {
    return const OfflineStatusState(
      connectionStatus: OfflineConnectionStatus.unknown,
      bootstrapStatus: OfflineBootstrapStatus.initial,
      salesSyncStatus: OfflineSalesSyncStatus.idle,
      hasCache: false,
      canUseAppOffline: false,
      pendingSalesCount: 0,
      lastSalesSyncAt: null,
      errorMessage: null,
    );
  }

  bool get isOnline => connectionStatus == OfflineConnectionStatus.online;

  bool get isOffline => connectionStatus == OfflineConnectionStatus.offline;

  bool get isBootstrapLoading =>
      bootstrapStatus == OfflineBootstrapStatus.loading;

  bool get isSalesSyncing => salesSyncStatus == OfflineSalesSyncStatus.syncing;

  bool get isBusy => isBootstrapLoading || isSalesSyncing;

  bool get hasFailure {
    return bootstrapStatus == OfflineBootstrapStatus.failure ||
        salesSyncStatus == OfflineSalesSyncStatus.failure;
  }

  OfflineStatusState copyWith({
    OfflineConnectionStatus? connectionStatus,
    OfflineBootstrapStatus? bootstrapStatus,
    OfflineSalesSyncStatus? salesSyncStatus,
    bool? hasCache,
    bool? canUseAppOffline,
    int? pendingSalesCount,
    DateTime? lastSalesSyncAt,
    bool clearLastSalesSyncAt = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    FirstSetupStatus? setupStatus,
    bool? setupRefreshing,
  }) {
    return OfflineStatusState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      bootstrapStatus: bootstrapStatus ?? this.bootstrapStatus,
      salesSyncStatus: salesSyncStatus ?? this.salesSyncStatus,
      hasCache: hasCache ?? this.hasCache,
      canUseAppOffline: canUseAppOffline ?? this.canUseAppOffline,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      lastSalesSyncAt: clearLastSalesSyncAt
          ? null
          : lastSalesSyncAt ?? this.lastSalesSyncAt,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      setupStatus: setupStatus ?? this.setupStatus,
      setupRefreshing: setupRefreshing ?? this.setupRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    connectionStatus,
    bootstrapStatus,
    salesSyncStatus,
    hasCache,
    canUseAppOffline,
    pendingSalesCount,
    lastSalesSyncAt,
    errorMessage,
    setupStatus,
    setupRefreshing,
  ];
}
