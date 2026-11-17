import 'dart:async';
import 'dart:io';

import 'package:amana_pos/core/sync/appliers/applier_support.dart'
    show kSyncedAssetsTable;
import 'package:flutter/foundation.dart';

/// One `synced_assets` row that holds a downloaded file.
typedef SyncedAssetPath = ({String url, String path});

/// Result of a lookup: [resolved] false until the first load finished
/// (the widget shows its placeholder); then [path] is the local file, or
/// null = use the network.
@immutable
class LocalImageLookup {
  const LocalImageLookup.pending() : resolved = false, path = null;
  const LocalImageLookup.resolved(this.path) : resolved = true;

  final bool resolved;
  final String? path;

  @override
  bool operator ==(Object other) =>
      other is LocalImageLookup &&
      other.resolved == resolved &&
      other.path == path;

  @override
  int get hashCode => Object.hash(resolved, path);
}

/// The single, app-wide url -> local file resolver behind every
/// `OfflineCachedImage` (F5). Holds a map of the `synced_assets` rows that
/// have a file, refreshed with ONE query per (debounced) `synced_assets`
/// notification, and only while some image is subscribed. Each widget
/// listens to a per-url [ValueListenable]; subscriptions are ref-counted
/// and released on dispose.
///
/// Matching mirrors `OfflineLocalCache.getSyncedAssetPathByUrl`: the exact
/// url first, then any row with the same url without its `?query` (newest
/// first), at most 4 candidates, the first whose file exists. Never throws:
/// a failed load resolves every url to null (network).
class LocalImageResolver {
  LocalImageResolver({
    required Future<List<SyncedAssetPath>> Function() load,
    required Stream<Set<String>> changes,
    Duration debounce = const Duration(milliseconds: 150),
  }) : _load = load,
       _debounce = debounce {
    _sub = changes.listen((tables) {
      if (!tables.contains(kSyncedAssetsTable)) return;
      _dirty = true;
      if (_entries.isEmpty) return; // loaded lazily on the next subscribe
      _timer?.cancel();
      _timer = Timer(_debounce, _refresh);
    });
  }

  final Future<List<SyncedAssetPath>> Function() _load;
  final Duration _debounce;
  late final StreamSubscription<Set<String>> _sub;
  Timer? _timer;
  bool _disposed = false;

  final Map<String, _Entry> _entries = {};

  /// base url (no `?query`) -> rows, newest first.
  Map<String, List<SyncedAssetPath>>? _byBase;
  bool _dirty = true;
  Future<void>? _loading;
  int _generation = 0;

  @visibleForTesting
  int get debugSubscribedUrls => _entries.length;

  /// Subscribes to [url] (trimmed, non-empty). Pair with [release].
  ValueListenable<LocalImageLookup> acquire(String url) {
    final existing = _entries[url];
    if (existing != null) {
      existing.refs++;
      return existing.value;
    }
    final entry = _Entry();
    _entries[url] = entry;
    if (_dirty || _byBase == null) {
      _scheduleLoad();
    } else {
      unawaited(_resolveOne(url, entry, _generation));
    }
    return entry.value;
  }

  void release(String url) {
    final entry = _entries[url];
    if (entry == null) return;
    if (--entry.refs > 0) return;
    _entries.remove(url);
    entry.value.dispose();
    if (_entries.isEmpty) _timer?.cancel();
  }

  /// Coalesces the subscriptions of one frame into a single load.
  void _scheduleLoad() {
    _loading ??= Future<void>(() async {
      try {
        await _refresh();
      } finally {
        _loading = null;
      }
    });
  }

  Future<void> _refresh() async {
    if (_disposed || _entries.isEmpty) return;
    final gen = ++_generation;
    _dirty = false;
    Map<String, List<SyncedAssetPath>> index;
    try {
      index = _index(await _load());
    } catch (e) {
      index = const {};
    }
    if (_disposed || gen != _generation) return;
    _byBase = index;
    await Future.wait([
      for (final e in _entries.entries.toList())
        _resolveOne(e.key, e.value, gen),
    ]);
  }

  Future<void> _resolveOne(String url, _Entry entry, int gen) async {
    final path = await _pathFor(url, _byBase ?? const {});
    if (_disposed || gen != _generation || _entries[url] != entry) return;
    entry.value.value = LocalImageLookup.resolved(path);
  }

  static Map<String, List<SyncedAssetPath>> _index(List<SyncedAssetPath> rows) {
    final out = <String, List<SyncedAssetPath>>{};
    for (final r in rows) {
      final base = _base(r.url);
      if (base.isEmpty || r.path.isEmpty) continue;
      (out[base] ??= []).add(r);
    }
    return out;
  }

  static String _base(String url) {
    final q = url.indexOf('?');
    return q < 0 ? url : url.substring(0, q);
  }

  static Future<String?> _pathFor(
    String raw,
    Map<String, List<SyncedAssetPath>> byBase,
  ) async {
    final rows = byBase[_base(raw)];
    if (rows == null) return null;
    final ordered = [
      ...rows.where((r) => r.url == raw),
      ...rows.where((r) => r.url != raw),
    ].take(4);
    for (final r in ordered) {
      try {
        if (await File(r.path).exists()) return r.path;
      } catch (_) {}
    }
    return null;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_sub.cancel());
    for (final e in _entries.values) {
      e.value.dispose();
    }
    _entries.clear();
  }
}

class _Entry {
  final ValueNotifier<LocalImageLookup> value = ValueNotifier(
    const LocalImageLookup.pending(),
  );
  int refs = 1;
}
