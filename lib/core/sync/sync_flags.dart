/// Compile-time switch for the offline-first sync core.
///
/// OFF by default: with the flag off nothing in `lib/core/sync` is
/// instantiated, no trigger runs, and the app behaves exactly as before
/// (legacy `SyncManager` / `OfflineSalesQueue` path).
///
/// Turn it on for a build or run with:
///   flutter run --dart-define=SYNC_ENGINE=true
const bool kSyncEngineEnabled = bool.fromEnvironment(
  'SYNC_ENGINE',
  defaultValue: false,
);

/// Ping capabilities the sync engine needs before any trigger may run it.
/// Unknown/missing capability = stay on the legacy online path.
const Set<String> kSyncRequiredCapabilities = {'push', 'pull'};
