import 'dart:async';
import 'dart:developer' as developer;

/// Pull-to-refresh on the catalog screens (products, categories, vendors):
/// besides re-reading SQLite, asks the sync triggers for a run. Fire and
/// forget: the lists re-read on their own when the pull lands
/// (`DbChangeNotifier`), and an offline or failed run never surfaces here.
void requestCatalogSync(Future<void> Function()? syncNow) {
  if (syncNow == null) return;
  unawaited(
    Future.sync(syncNow).catchError((Object e, StackTrace st) {
      developer.log(
        'catalog refresh sync failed',
        name: 'sync',
        error: e,
        stackTrace: st,
      );
    }),
  );
}
