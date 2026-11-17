import 'dart:async';

import 'package:flutter/foundation.dart';

import '../sync_schema.dart';
import 'pending_upload_store.dart';

/// The single, app-wide `entity|id -> staged file` map behind
/// `OfflineCachedImage` (Task 6): an entity with a `pending_uploads` row in
/// the current scope shows its staged file first (the picked image is the
/// truth until the uploader has sent it and AssetSync has the served one).
///
/// ONE load per (debounced) `pending_uploads` notification, and only while
/// some widget is subscribed (ref-counted [acquire] / [release]); otherwise
/// the next [acquire] loads. [paths] is null until the first load finished.
/// Never throws: a failed load is an empty map (the widget falls back to
/// its url).
class PendingImageResolver {
  /// [scopeOf]: the signed-in scope. A map loaded for another scope is
  /// never handed out: [acquire] after a user switch clears it and reloads
  /// (T6 review M3; `pending_uploads` rows survive logout).
  PendingImageResolver({
    required Future<Map<String, String>> Function() load,
    required Stream<Set<String>> changes,
    String? Function()? scopeOf,
    Duration debounce = const Duration(milliseconds: 150),
  }) : _load = load,
       _scopeOf = scopeOf,
       _debounce = debounce {
    _sub = changes.listen((tables) {
      if (!tables.contains(SyncTables.pendingUploads)) return;
      _dirty = true;
      if (_subscribers == 0) return;
      _timer?.cancel();
      _timer = Timer(_debounce, _refresh);
    });
  }

  final Future<Map<String, String>> Function() _load;
  final String? Function()? _scopeOf;
  String? _loadedScope;
  final Duration _debounce;
  late final StreamSubscription<Set<String>> _sub;
  final ValueNotifier<Map<String, String>?> _paths = ValueNotifier(null);
  Timer? _timer;
  int _subscribers = 0;
  bool _dirty = true;
  bool _disposed = false;
  int _generation = 0;

  static String keyOf(String entity, String entityId) => '$entity|$entityId';

  /// `entity|id -> absolute staged path` of [uploads] (any state: a parked
  /// `failed` upload is still the image the user picked).
  static Map<String, String> pathsOf(Iterable<PendingUpload> uploads) => {
    for (final u in uploads) keyOf(u.entity, u.entityId): u.localPath,
  };

  /// null until loaded.
  ValueListenable<Map<String, String>?> get paths => _paths;

  @visibleForTesting
  int get debugSubscribers => _subscribers;

  /// Subscribes (pair with [release]); loads when stale.
  ValueListenable<Map<String, String>?> acquire() {
    _subscribers++;
    final scopeOf = _scopeOf;
    if (scopeOf != null && _paths.value != null && scopeOf() != _loadedScope) {
      _paths.value = null; // another account's staged files: never shown
      _dirty = true;
    }
    if (_dirty) {
      _dirty = false;
      unawaited(Future<void>(_refresh));
    }
    return _paths;
  }

  void release() {
    if (_subscribers == 0) return;
    if (--_subscribers == 0) _timer?.cancel();
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    final gen = ++_generation;
    _dirty = false;
    final scope = _scopeOf?.call();
    Map<String, String> next;
    try {
      next = await _load();
    } catch (_) {
      next = const {};
    }
    if (_disposed || gen != _generation) return;
    _loadedScope = scope;
    final old = _paths.value;
    if (old != null && mapEquals(old, next)) return;
    _paths.value = Map.unmodifiable(next);
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_sub.cancel());
    _paths.dispose();
  }
}
