import '../../offline/offline_db.dart';
import '../db_change_notifier.dart';
import '../sync_engine.dart';
import '../transport/image_upload_transport.dart';
import '../transport/sync_transport.dart';
import 'image_uploader.dart';
import 'pending_image_resolver.dart';
import 'pending_upload_store.dart';

/// Construction rules for [ImageUploader] (app DI only: the OS background
/// worker never builds one, uploads are foreground-only).
///
/// [transport] is the app's sync transport; it must also implement
/// [ImageUploadTransport] (`HttpSyncTransport` does). Returns null when it
/// does not, so the triggers simply run no uploads.
ImageUploader? buildImageUploader({
  required OfflineDb db,
  required PendingUploadStore store,
  required SyncTransport transport,
  required DbChangeNotifier notifier,
  required String? Function() scopeProvider,
  required AuthedCall Function(String scope) authedFor,
}) {
  if (transport is! ImageUploadTransport) return null;
  return ImageUploader(
    db: db,
    store: store,
    transport: transport as ImageUploadTransport,
    notifier: notifier,
    scopeProvider: scopeProvider,
    authedFor: authedFor,
  );
}

/// The app-wide [PendingImageResolver]: staged uploads of the CURRENT scope
/// (read at load time), keyed `entity|id`.
PendingImageResolver buildPendingImageResolver({
  required OfflineDb db,
  required PendingUploadStore store,
  required DbChangeNotifier notifier,
  required String? Function() scopeProvider,
}) => PendingImageResolver(
  changes: notifier.changes,
  scopeOf: scopeProvider,
  load: () async {
    final scope = scopeProvider();
    if (scope == null) return const {};
    final rows = await store.all(await db.database, scope: scope);
    return PendingImageResolver.pathsOf(rows);
  },
);
