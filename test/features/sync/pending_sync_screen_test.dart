import 'dart:async';

import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/features/sync/presentation/bloc/sync_badge_cubit.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/pending_sync_screen.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<PendingSyncEvent, PendingSyncState>
    implements PendingSyncBloc {}

/// Review M2: the pending screen shows refusals / failures, has a retry-all
/// button, an empty state, and formats sale totals as money.
void main() {
  setUpAll(() => registerFallbackValue(const OnPendingSyncLoad()));
  setUp(() async {
    await getIt.reset();
    getIt.registerSingletonAsync<SyncBadgeCubit>(
      () async => SyncBadgeCubit(
        status: const Stream<SyncStatus>.empty(),
        initial: const SyncStatus(),
        unsyncedCount: () async => 0,
      ),
    );
    await getIt.allReady();
  });
  tearDown(() => getIt.reset());

  PendingSyncRow row({
    required String id,
    OutboxStatus status = OutboxStatus.pending,
    String? total,
    bool otherScope = false,
    int attempts = 0,
  }) => PendingSyncRow(
    entry: OutboxEntry(
      mutationId: id,
      entity: 'sale',
      op: 'create',
      entityId: 'sale-$id',
      occurredAt: DateTime.utc(2026),
      payload: const {},
      status: status,
      scope: otherScope ? 'u2|t' : 'u1|t',
      attempts: attempts,
    ),
    label: 'L-$id',
    total: total,
    otherScope: otherScope,
  );

  Widget wrap(PendingSyncBloc bloc, {Locale locale = const Locale('en')}) =>
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PendingSyncBloc>.value(
          value: bloc,
          child: const PendingSyncScreen(),
        ),
      );

  Future<void> pump(WidgetTester t, Widget w) async {
    await t.pumpWidget(w);
    await t.pump(const Duration(milliseconds: 50));
  }

  testWidgets('empty list shows the all-synced empty state', (t) async {
    final bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<PendingSyncState>.empty(),
      initialState: const PendingSyncState(status: PendingSyncStatus.loaded),
    );
    await pump(t, wrap(bloc));
    expect(find.text('Everything is synced'), findsOneWidget);
  });

  testWidgets('retry-all is shown for own rejected rows and dispatches '
      'OnPendingSyncRetryAll; totals are formatted as money', (t) async {
    final bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<PendingSyncState>.empty(),
      initialState: PendingSyncState(
        status: PendingSyncStatus.loaded,
        rows: [
          row(id: 'a', status: OutboxStatus.rejected, total: '26400.00'),
          row(id: 'b'),
        ],
      ),
    );
    await pump(t, wrap(bloc));
    expect(find.textContaining('26,400 SDG'), findsOneWidget);
    expect(find.textContaining('26400.00'), findsNothing);
    await t.tap(find.text('Retry all rejected'));
    verify(() => bloc.add(const OnPendingSyncRetryAll())).called(1);
  });

  testWidgets('no retry-all without own rejected rows', (t) async {
    final bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<PendingSyncState>.empty(),
      initialState: PendingSyncState(
        status: PendingSyncStatus.loaded,
        rows: [
          row(id: 'a'),
          row(id: 'f', status: OutboxStatus.rejected, otherScope: true),
        ],
      ),
    );
    await pump(t, wrap(bloc));
    expect(find.text('Retry all rejected'), findsNothing);
  });

  testWidgets('a refused discard is shown in a snackbar (en + ar)', (t) async {
    for (final (locale, text) in [
      (const Locale('en'), 'This change is being sent right now'),
      (const Locale('ar'), 'يتم إرسال هذا التغيير الآن'),
    ]) {
      final bloc = _MockBloc();
      final loaded = PendingSyncState(
        status: PendingSyncStatus.loaded,
        rows: [row(id: 'a', status: OutboxStatus.inflight)],
      );
      final states = StreamController<PendingSyncState>();
      whenListen(bloc, states.stream, initialState: loaded);
      await pump(t, wrap(bloc, locale: locale));
      states.add(loaded.withFailure(PendingSyncFailure.discardSending, null));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.textContaining(text), findsOneWidget);
      await states.close();
      await t.pumpWidget(const SizedBox());
    }
  });

  group('fix round 1: discard of a row that was already sent once', () {
    Future<_MockBloc> open(WidgetTester t, int attempts) async {
      final bloc = _MockBloc();
      whenListen(
        bloc,
        const Stream<PendingSyncState>.empty(),
        initialState: PendingSyncState(
          status: PendingSyncStatus.loaded,
          rows: [row(id: 'a', attempts: attempts)],
        ),
      );
      await pump(t, wrap(bloc));
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      return bloc;
    }

    testWidgets('attempts > 0: stronger warning and Send now', (t) async {
      final bloc = await open(t, 2);
      expect(
        find.textContaining('may already be on the server'),
        findsOneWidget,
      );
      expect(find.text('Send now'), findsOneWidget);
      await t.tap(find.text('Send now'));
      await t.pumpAndSettle();
      verify(() => bloc.add(const OnPendingSyncSendNow())).called(1);
      verifyNever(() => bloc.add(const OnPendingSyncDiscardRow('a')));
    });

    testWidgets('attempts > 0: Discard stays possible', (t) async {
      final bloc = await open(t, 1);
      // The sheet's destructive action (the row button is behind the sheet).
      await t.tap(find.text('Discard').last);
      await t.pumpAndSettle();
      verify(() => bloc.add(const OnPendingSyncDiscardRow('a'))).called(1);
    });

    testWidgets('attempts == 0: normal text, no Send now', (t) async {
      await open(t, 0);
      expect(find.text('Discard this sale?'), findsOneWidget);
      expect(
        find.textContaining('The sale stays on this phone marked as rejected'),
        findsOneWidget,
      );
      expect(find.textContaining('may already be on the server'), findsNothing);
      expect(find.text('Send now'), findsNothing);
    });
  });
}
