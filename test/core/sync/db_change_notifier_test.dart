import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';

const _deb = Duration(milliseconds: 10);
Future<void> _wait([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late DbChangeNotifier n;
  setUp(() => n = DbChangeNotifier());
  tearDown(() => n.dispose());

  test('watch emits initial value', () async {
    final s = n.watch<int>(
      tables: {'sales'},
      query: () async => 1,
      debounce: _deb,
    );
    expect(await s.first, 1);
  });

  test('notify re-queries only intersecting watchers', () async {
    var sales = 0, products = 0;
    final a = <int>[], b = <int>[];
    final s1 = n
        .watch<int>(
          tables: {'sales'},
          query: () async => ++sales,
          debounce: _deb,
        )
        .listen(a.add);
    final s2 = n
        .watch<int>(
          tables: {'products'},
          query: () async => ++products,
          debounce: _deb,
        )
        .listen(b.add);
    await _wait();
    n.notify({'sales'});
    await _wait();
    expect(a, [1, 2]);
    expect(b, [1]);
    await s1.cancel();
    await s2.cancel();
  });

  test('burst of notifies coalesces into one re-query', () async {
    var calls = 0;
    final sub = n
        .watch<int>(
          tables: {'sales'},
          query: () async => ++calls,
          debounce: _deb,
        )
        .listen((_) {});
    await _wait();
    for (var i = 0; i < 10; i++) {
      n.notify({'sales'});
    }
    await _wait();
    expect(calls, 2);
    await sub.cancel();
  });

  test('slow earlier query never overwrites later one', () async {
    final c = <Completer<int>>[Completer<int>(), Completer<int>()];
    var i = 0;
    final out = <int>[];
    final sub = n
        .watch<int>(
          tables: {'sales'},
          query: () => c[i++].future,
          debounce: _deb,
        )
        .listen(out.add);
    await _wait(); // query #1 pending
    n.notify({'sales'});
    await _wait(); // query #2 started
    c[1].complete(2);
    await _wait();
    c[0].complete(1);
    await _wait();
    expect(out, [2]);
    await sub.cancel();
  });

  test('cancel stops queries', () async {
    var calls = 0;
    final sub = n
        .watch<int>(
          tables: {'sales'},
          query: () async => ++calls,
          debounce: _deb,
        )
        .listen((_) {});
    await _wait();
    await sub.cancel();
    n.notify({'sales'});
    await _wait();
    expect(calls, 1);
  });
}
