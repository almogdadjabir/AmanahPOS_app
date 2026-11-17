import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../common/services/device/device_info_service.dart';
import '../../../common/services/local/local_storage.dart';
import '../../../config/constants.dart';
import '../../../config/environment/environment.dart';
import '../../offline/offline_db.dart';
import '../assets/asset_sync_wiring.dart';
import '../change_applier.dart';
import '../db_change_notifier.dart';
import '../outbox/outbox_store.dart';
import '../reachability.dart';
import '../sync_appliers.dart';
import '../sync_engine.dart';
import '../sync_flags.dart';
import '../sync_state_store.dart';
import '../sync_token_refresher.dart';
import '../transport/http_sync_transport.dart';
import 'background_sync.dart';

/// Periodic task (Android unique work name; iOS BGAppRefreshTask id).
const String kBackgroundSyncPeriodic = 'amana.sync';

/// One-off task enqueued when a write lands while the app is backgrounded.
const String kBackgroundSyncOneOff = 'amana.sync.now';

/// iOS BGProcessingTask id (runs when the device is idle, e.g. overnight).
const String kBackgroundSyncProcessing = 'amana.sync.processing';

/// SharedPreferences key holding the app version last seen by the
/// foreground (the native version channel is not registered in a headless
/// background engine).
const String kSyncAppVersionPref = 'sync_app_version';

/// iOS: AppDelegate registers the BGTask launch handlers (amana.sync,
/// amana.sync.processing) before didFinishLaunching returns; without them
/// scheduling from Dart would make BGTaskScheduler throw.
const bool _iosWorkerReady = true;

bool get _platformSupported =>
    !kIsWeb && (Platform.isAndroid || (_iosWorkerReady && Platform.isIOS));

/// Registration of the OS background worker. Every method is a no-op when
/// [kSyncEngineEnabled] is false or the platform has no worker.
class BackgroundSync {
  BackgroundSync._();

  static bool _initialized = false;

  /// Initializes the plugin and (re)schedules the periodic task. Call once
  /// from `main` when the sync engine is enabled.
  static Future<void> initialize() async {
    if (!kSyncEngineEnabled || !_platformSupported || _initialized) return;
    try {
      await Workmanager().initialize(callbackDispatcher);
      _initialized = true;
      await register();
    } catch (e, st) {
      _log('initialize failed', e, st);
    }
  }

  /// Schedules the periodic sync: every 15 min (the OS minimum), only with
  /// a network connection. Not constrained on battery: unsynced sales are
  /// money.
  static Future<void> register() async {
    if (!kSyncEngineEnabled || !_platformSupported) return;
    final constraints = Constraints(networkType: NetworkType.connected);
    await Workmanager().registerPeriodicTask(
      kBackgroundSyncPeriodic,
      kBackgroundSyncPeriodic,
      frequency: const Duration(minutes: 15),
      initialDelay: Platform.isIOS ? const Duration(minutes: 15) : null,
      constraints: constraints,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
    if (Platform.isIOS) {
      await Workmanager().registerProcessingTask(
        kBackgroundSyncProcessing,
        kBackgroundSyncProcessing,
        constraints: constraints,
      );
    }
  }

  /// Asks the OS for one sync soon (expedited on Android 12+ when quota
  /// allows, see [shouldExpedite]). Fire-and-forget; repeated calls collapse
  /// into one task.
  static void requestSoon() {
    if (!kSyncEngineEnabled || !_platformSupported || !_initialized) return;
    unawaited(
      () async {
        final expedited = await shouldExpedite();
        await Workmanager().registerOneOffTask(
          kBackgroundSyncOneOff,
          kBackgroundSyncOneOff,
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingWorkPolicy.keep,
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(seconds: 30),
          expedited: expedited,
          outOfQuotaPolicy: expedited
              ? OutOfQuotaPolicy.runAsNonExpeditedWorkRequest
              : null,
        );
      }().catchError((Object e, StackTrace st) {
        _log('one-off enqueue failed', e, st);
      }),
    );
  }

  /// Android SDK level of this device (null when unknown).
  @visibleForTesting
  static Future<int?> Function() androidSdkInt =
      DeviceInfoService.instance.getAndroidSdkInt;

  /// Expedited one-off work only on Android 12+ (API 31). On API < 31
  /// WorkManager runs expedited work as a foreground service and calls
  /// `getForegroundInfoAsync()`, which workmanager_android 0.10.9's
  /// BackgroundWorker does not implement: the run would fail every time
  /// (review I3). Unknown SDK (lookup failed) => a normal one-off with the
  /// same constraints.
  static Future<bool> shouldExpedite({
    bool? isAndroid,
    Future<int?> Function()? sdkInt,
  }) async {
    if (!(isAndroid ?? (!kIsWeb && Platform.isAndroid))) return false;
    try {
      final v = await (sdkInt ?? androidSdkInt)();
      return v != null && v >= 31;
    } catch (_) {
      return false;
    }
  }

  /// Remembers the app version for the background engine.
  static Future<void> rememberAppVersion(String version) async {
    if (version.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kSyncAppVersionPref, version);
    } catch (_) {}
  }
}

/// The engine of the run in progress in this isolate, so an OS stop
/// (Android) can cancel it between batches.
SyncEngine? _activeEngine;

/// Background isolate entry point (Android WorkManager / iOS BGTask).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (task, inputData) async {
      if (!kSyncEngineEnabled) return true;
      final report = await runBackgroundSync();
      _log('task $task -> $report');
      return !report.shouldRetry;
    },
    onTaskStopped: (task, reason) async {
      _log('task $task stopped by the OS: $reason');
      _activeEngine?.cancel();
    },
  );
}

/// Builds the minimal sync stack (no UI, no Bloc, no get_it) on the shared
/// database file and runs [BackgroundSyncRunner.runOnce].
///
/// The database is never closed here: on Android and iOS sqflite shares one
/// native connection per file across isolates of the process, so closing it
/// would close the foreground app's connection too.
Future<BackgroundSyncReport> runBackgroundSync({
  Duration budget = BackgroundSyncRunner.defaultBudget,
}) async {
  final storage = CacheStorage();
  Future<String?> readAccessToken() => storage.getValue(Constants.authToken);
  Future<String?> readTenantId() => storage.getValue(Constants.xTenantID);
  // From storage (no AuthBloc here). The interceptor still refuses any
  // request whose token claim / tenant do not match the request's scope.
  Future<String?> readSessionKey() async =>
      BackgroundSyncRunner.storageSessionKey(
        await readAccessToken(),
        await readTenantId(),
      );

  final odb = OfflineDb.instance;
  final state = SyncStateStore(odb);
  final transport = HttpSyncTransport.create(
    baseUrl: baseUrl,
    readAccessToken: readAccessToken,
    readTenantId: readTenantId,
    readDeviceId: state.deviceId,
    readSessionKey: readSessionKey,
  );
  final reachability = ServerReachability(transport);

  try {
    return await BackgroundSyncRunner.runOnce(
      readSessionKey: readSessionKey,
      budget: budget,
      // Same gate as the foreground: unknown capabilities = legacy path.
      // Unreachable: let the engine run its ping and report backoff.
      canSync: () async {
        final ping = await reachability.check();
        return ping == null ||
            ping.capabilities.containsAll(kSyncRequiredCapabilities);
      },
      // Thumbnails only, after a completed sync, inside the same budget. Own
      // instance (own isolate): same plain-Dio rules and the same folder as
      // the app's AssetSync; scope fixed to this run's session.
      assetSyncFactory: (scope) async => buildAssetSync(
        db: odb,
        notifier: DbChangeNotifier(),
        scopeProvider: () => scope,
        appSupportPath: (await getApplicationSupportDirectory()).path,
        baseUrl: baseUrl,
        readAccessToken: readAccessToken,
        readTenantId: readTenantId,
      ),
      engineFactory: (scope) async {
        final engine = SyncEngine(
          db: odb,
          transport: transport,
          outbox: OutboxStore(odb),
          state: state,
          scopeProvider: () => scope,
          readSessionKey: readSessionKey,
          reachability: reachability,
          appliers: backgroundSyncAppliers(scope),
          notifier: DbChangeNotifier(),
          appVersion: await _appVersion(),
          refreshToken: SyncTokenRefresher(
            baseUrl: baseUrl,
            storage: storage,
          ).refresh,
        );
        _activeEngine = engine;
        return engine;
      },
    );
  } finally {
    _activeEngine = null;
    await reachability.dispose();
  }
}

/// The worker's appliers write under ITS session scope (shop
/// `business_id`, category `tenant_id`), never `SyncScope.current`, which
/// is not set in a headless isolate. No `Bootstrapper` is built here: the
/// worker never bootstraps (it reports `needsBootstrap` as success and
/// leaves first setup to the foreground app).
ChangeApplierRegistry backgroundSyncAppliers(String scope) =>
    buildSyncAppliers(scopeProvider: () => scope);

Future<String> _appVersion() async {
  final live = await DeviceInfoService.instance.getAppVersion();
  if (live.isNotEmpty) return live;
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kSyncAppVersionPref) ?? '';
  } catch (_) {
    return ''; // unparseable/empty never blocks sync (engine rule)
  }
}

void _log(String msg, [Object? e, StackTrace? st]) {
  developer.log(msg, name: 'BackgroundSync', error: e, stackTrace: st);
}
