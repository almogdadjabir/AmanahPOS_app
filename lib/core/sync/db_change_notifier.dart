import 'dart:async';

/// Broadcasts which tables changed and offers reactive, debounced queries.
class DbChangeNotifier {
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast(sync: true);

  void notify(Set<String> tables) {
    if (tables.isEmpty || _controller.isClosed) return;
    _controller.add(Set.unmodifiable(tables));
  }

  Stream<Set<String>> get changes => _controller.stream;

  /// Emits the initial query result, then re-runs [query] after any [notify]
  /// intersecting [tables]. Bursts within [debounce] coalesce; stale results
  /// (older generation) are dropped.
  Stream<T> watch<T>({
    required Set<String> tables,
    required Future<T> Function() query,
    Duration debounce = const Duration(milliseconds: 16),
  }) {
    late final StreamController<T> out;
    StreamSubscription<Set<String>>? sub;
    Timer? timer;
    var generation = 0;
    var active = false;

    Future<void> run() async {
      final gen = ++generation;
      try {
        final value = await query();
        if (active && gen == generation && !out.isClosed) out.add(value);
      } catch (e, st) {
        if (active && gen == generation && !out.isClosed) {
          out.addError(e, st);
        }
      }
    }

    out = StreamController<T>(
      onListen: () {
        active = true;
        sub = changes.listen((changed) {
          if (changed.intersection(tables).isEmpty) return;
          timer?.cancel();
          timer = Timer(debounce, run);
        });
        run();
      },
      onCancel: () async {
        active = false;
        generation++;
        timer?.cancel();
        await sub?.cancel();
      },
    );
    return out.stream;
  }

  void dispose() {
    _controller.close();
  }
}
