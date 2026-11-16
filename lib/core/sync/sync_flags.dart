/// Compile-time switch for the offline-first sync engine.
///
/// ON by default. Sales and stock edits are ALWAYS written locally + to the
/// outbox (`SaleService` / `StockService`); this flag only gates the engine,
/// its triggers and the OS background worker.
///
/// Kill switch for a build or run:
///   flutter run --dart-define=SYNC_ENGINE=false
/// With it off, local saves keep working and queue in the outbox; nothing
/// syncs until a build with the engine on runs.
const bool kSyncEngineEnabled = bool.fromEnvironment(
  'SYNC_ENGINE',
  defaultValue: true,
);

/// Ping capabilities the sync engine needs before any trigger may run it.
/// Unknown/missing capability = the engine does not run.
const Set<String> kSyncRequiredCapabilities = {'push', 'pull'};
