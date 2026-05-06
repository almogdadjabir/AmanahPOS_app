part of 'offline_status_bloc.dart';

enum OfflineConnectionStatus { unknown, online, offline, }

enum OfflineBootstrapStatus { initial, loading, success, failure, }

enum OfflineAssetStatus { initial, loading, success, failure, }

enum OfflineSalesSyncStatus { idle, syncing, success, failure, }

class OfflineStatusState extends Equatable {
  final OfflineConnectionStatus connectionStatus;
  final OfflineBootstrapStatus bootstrapStatus;
  final OfflineAssetStatus assetStatus;
  final OfflineSalesSyncStatus salesSyncStatus;
  final bool hasCache;
  final bool canUseAppOffline;
  final int pendingSalesCount;
  final DateTime? lastBootstrapSyncAt;
  final DateTime? lastAssetSyncAt;
  final DateTime? lastSalesSyncAt;

  final String? errorMessage;

  const OfflineStatusState({
    required this.connectionStatus,
    required this.bootstrapStatus,
    required this.assetStatus,
    required this.salesSyncStatus,
    required this.hasCache,
    required this.canUseAppOffline,
    required this.pendingSalesCount,
    required this.lastBootstrapSyncAt,
    required this.lastAssetSyncAt,
    required this.lastSalesSyncAt,
    required this.errorMessage,
  });

  factory OfflineStatusState.initial() {
    return const OfflineStatusState(
      connectionStatus: OfflineConnectionStatus.unknown,
      bootstrapStatus: OfflineBootstrapStatus.initial,
      assetStatus: OfflineAssetStatus.initial,
      salesSyncStatus: OfflineSalesSyncStatus.idle,
      hasCache: false,
      canUseAppOffline: false,
      pendingSalesCount: 0,
      lastBootstrapSyncAt: null,
      lastAssetSyncAt: null,
      lastSalesSyncAt: null,
      errorMessage: null,
    );
  }

  bool get isOnline => connectionStatus == OfflineConnectionStatus.online;

  bool get isOffline => connectionStatus == OfflineConnectionStatus.offline;

  bool get isBootstrapLoading =>
      bootstrapStatus == OfflineBootstrapStatus.loading;

  bool get isAssetsLoading => assetStatus == OfflineAssetStatus.loading;

  bool get isSalesSyncing => salesSyncStatus == OfflineSalesSyncStatus.syncing;

  bool get isBusy => isBootstrapLoading || isAssetsLoading || isSalesSyncing;

  bool get hasFailure {
    return bootstrapStatus == OfflineBootstrapStatus.failure ||
        assetStatus == OfflineAssetStatus.failure ||
        salesSyncStatus == OfflineSalesSyncStatus.failure;
  }

  String get connectionLabel {
    switch (connectionStatus) {
      case OfflineConnectionStatus.online:
        return 'Online';
      case OfflineConnectionStatus.offline:
        return 'Offline';
      case OfflineConnectionStatus.unknown:
        return 'Checking';
    }
  }

  String get statusLabel {
    if (isBootstrapLoading) return 'Updating data';
    if (isAssetsLoading) return 'Updating assets';
    if (isSalesSyncing) return 'Syncing sales';

    if (pendingSalesCount > 0) {
      return '$pendingSalesCount pending';
    }

    if (isOffline && canUseAppOffline) {
      return 'Offline ready';
    }

    if (hasFailure) {
      return 'Sync failed';
    }

    if (lastSalesSyncAt != null || lastBootstrapSyncAt != null) {
      return 'Synced';
    }

    return 'Ready';
  }

  DateTime? get latestSyncAt {
    final dates = [
      lastSalesSyncAt,
      lastBootstrapSyncAt,
      lastAssetSyncAt,
    ].whereType<DateTime>().toList();

    if (dates.isEmpty) return null;

    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  OfflineStatusState copyWith({
    OfflineConnectionStatus? connectionStatus,
    OfflineBootstrapStatus? bootstrapStatus,
    OfflineAssetStatus? assetStatus,
    OfflineSalesSyncStatus? salesSyncStatus,
    bool? hasCache,
    bool? canUseAppOffline,
    int? pendingSalesCount,
    DateTime? lastBootstrapSyncAt,
    bool clearLastBootstrapSyncAt = false,
    DateTime? lastAssetSyncAt,
    bool clearLastAssetSyncAt = false,
    DateTime? lastSalesSyncAt,
    bool clearLastSalesSyncAt = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return OfflineStatusState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      bootstrapStatus: bootstrapStatus ?? this.bootstrapStatus,
      assetStatus: assetStatus ?? this.assetStatus,
      salesSyncStatus: salesSyncStatus ?? this.salesSyncStatus,
      hasCache: hasCache ?? this.hasCache,
      canUseAppOffline: canUseAppOffline ?? this.canUseAppOffline,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      lastBootstrapSyncAt: clearLastBootstrapSyncAt
          ? null
          : lastBootstrapSyncAt ?? this.lastBootstrapSyncAt,
      lastAssetSyncAt:
      clearLastAssetSyncAt ? null : lastAssetSyncAt ?? this.lastAssetSyncAt,
      lastSalesSyncAt:
      clearLastSalesSyncAt ? null : lastSalesSyncAt ?? this.lastSalesSyncAt,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    connectionStatus,
    bootstrapStatus,
    assetStatus,
    salesSyncStatus,
    hasCache,
    canUseAppOffline,
    pendingSalesCount,
    lastBootstrapSyncAt,
    lastAssetSyncAt,
    lastSalesSyncAt,
    errorMessage,
  ];
}