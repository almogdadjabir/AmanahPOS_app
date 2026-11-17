import 'dart:async';

import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/features/sync/presentation/bloc/sync_badge_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Review M3: the badge count follows local outbox writes (discard / retry
/// / a new sale), not only engine status changes.
void main() {
  test('an outbox table change refreshes the unsynced count', () async {
    final status = StreamController<SyncStatus>.broadcast();
    final notifier = DbChangeNotifier();
    var count = 3;
    final cubit = SyncBadgeCubit(
      status: status.stream,
      initial: const SyncStatus(),
      unsyncedCount: () async => count,
      tableChanges: notifier.changes,
    );
    await cubit.stream.firstWhere((s) => s.unsynced == 3);

    count = 2; // a discard removed one row; the engine did not run
    notifier.notify({'outbox'});
    await cubit.stream
        .firstWhere((s) => s.unsynced == 2)
        .timeout(const Duration(seconds: 2));

    // Unrelated tables do not re-query.
    count = 1;
    notifier.notify({'products'});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.unsynced, 2);

    await cubit.close();
    await status.close();
    notifier.dispose();
  });
}
