import 'package:amana_pos/core/sync/bootstrap/bootstrap_controller.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart' show pushOnlyEntities;
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/sync_token_refresher.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    DependenciesProvider.build();
  });
  tearDown(() => getIt.reset());

  test('flag is ON by default (kill switch: SYNC_ENGINE=false)', () {
    expect(
      kSyncEngineEnabled,
      const bool.fromEnvironment('SYNC_ENGINE', defaultValue: true),
    );
    if (!const bool.hasEnvironment('SYNC_ENGINE')) {
      expect(kSyncEngineEnabled, isTrue);
    }
  });

  test(
    'kill switch: startSyncIfEnabled builds no engine; SyncScope follows the '
    'session so local writes still reach the outbox',
    () async {
      await DependenciesProvider.startSyncIfEnabled();
      expect(getIt.checkLazySingletonInstanceExists<SyncEngine>(), isFalse);
      expect(getIt.checkLazySingletonInstanceExists<SyncTriggers>(), isFalse);
      expect(getIt.checkLazySingletonInstanceExists<Bootstrapper>(), isFalse);
      expect(
        getIt.checkLazySingletonInstanceExists<BootstrapController>(),
        isFalse,
      );
      expect(
        getIt.checkLazySingletonInstanceExists<SyncCoordinator>(),
        isFalse,
      );
      // Signed out: no scope to enqueue under.
      expect(SyncScope.current, isNull);
    },
    skip: kSyncEngineEnabled
        ? 'only with --dart-define=SYNC_ENGINE=false'
        : false,
  );

  test('sync core registrations resolve (lazily, nothing started)', () async {
    expect(getIt<DbChangeNotifier>(), isA<DbChangeNotifier>());
    expect(getIt<OutboxStore>(), isA<OutboxStore>());
    expect(getIt<LocalWriter>(), isA<LocalWriter>());
    expect(getIt<SyncStateStore>(), isA<SyncStateStore>());
    expect(getIt<SyncTransport>(), isA<HttpSyncTransport>());
    expect(
      getIt<Dio>(instanceName: DependenciesProvider.syncDioName),
      isNot(same(getIt<Dio>())),
      reason: 'sync has its own Dio, never the app Dio with AppInterceptors',
    );
    expect(getIt<ServerReachability>(), isA<ServerReachability>());
    expect(
        getIt<ChangeApplierRegistry>().all
            .map((a) => a.entity)
            .where((e) => !pushOnlyEntities.contains(e)), [
      'business',
      'shop',
      'category',
      'product',
      'stock',
      'sale',
      'refund',
      'inbound',
      'customer',
      'vendor',
      'expiry_batch',
      'user',
      'subscription',
      'notification',
      'bankak_account',
    ]);
    expect(getIt<SaleService>(), isA<SaleService>());
    expect(getIt<StockService>(), isA<StockService>());
    expect(getIt<SyncTokenRefresher>(), isA<SyncTokenRefresher>());
    expect(getIt<SyncDeviceRegistrar>(), isA<SyncDeviceRegistrar>());

    final engine = await getIt.getAsync<SyncEngine>();
    expect(identical(engine, await getIt.getAsync<SyncEngine>()), isTrue);
    final triggers = await getIt.getAsync<SyncTriggers>();
    expect(triggers.isStarted, isFalse);
    expect(await getIt.getAsync<SyncSessionGuard>(), isA<SyncSessionGuard>());
    final coordinator = await getIt.getAsync<SyncCoordinator>();
    expect(coordinator.currentSession, isNull);
    // Task 7: one Bootstrapper shared by the triggers and the UI accessor.
    final boot = await getIt.getAsync<Bootstrapper>();
    expect(identical(boot, await getIt.getAsync<Bootstrapper>()), isTrue);
    final ctrl = await getIt.getAsync<BootstrapController>();
    expect(ctrl.current.outcome, isNull, reason: 'nothing ran');
    SyncScope.current = null;
    expect(await ctrl.isTenantBootstrapped(), isFalse, reason: 'no scope');
    await engine.dispose();
  });
}
