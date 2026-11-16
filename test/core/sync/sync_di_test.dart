import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/sync_token_refresher.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
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

  test('flag is off by default (no behaviour change)', () {
    expect(kSyncEngineEnabled, isFalse);
  });

  test('startSyncIfEnabled constructs nothing when the flag is off', () async {
    await DependenciesProvider.startSyncIfEnabled();
    expect(getIt.checkLazySingletonInstanceExists<SyncEngine>(), isFalse);
    expect(getIt.checkLazySingletonInstanceExists<SyncTriggers>(), isFalse);
    expect(getIt.checkLazySingletonInstanceExists<SyncCoordinator>(), isFalse);
    expect(getIt.checkLazySingletonInstanceExists<OutboxStore>(), isFalse);
  });

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
    expect(getIt<ChangeApplierRegistry>().all, isEmpty);
    expect(getIt<SyncTokenRefresher>(), isA<SyncTokenRefresher>());
    expect(getIt<SyncDeviceRegistrar>(), isA<SyncDeviceRegistrar>());

    final engine = await getIt.getAsync<SyncEngine>();
    expect(identical(engine, await getIt.getAsync<SyncEngine>()), isTrue);
    final triggers = await getIt.getAsync<SyncTriggers>();
    expect(triggers.isStarted, isFalse);
    expect(await getIt.getAsync<SyncSessionGuard>(), isA<SyncSessionGuard>());
    final coordinator = await getIt.getAsync<SyncCoordinator>();
    expect(coordinator.currentSession, isNull);
    await engine.dispose();
  });
}
