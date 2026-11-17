import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/features/sync/domain/catalog_conflict_service.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/bloc/sync_badge_cubit.dart';
import 'package:amana_pos/features/sync/presentation/pending_sync_outbox_view.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const kCat = 'c0000000-0000-4000-8000-000000000001';
const kServer = 'aaaaaaaa-0000-4000-8000-000000000001';

class _MockBloc extends MockBloc<PendingSyncEvent, PendingSyncState>
    implements PendingSyncBloc {}

void main() {
  group('PendingSyncBloc (catalog rows)', () {
    late SaleFixture f;
    late Directory base;
    late PendingUploadStore uploads;
    late ProductService products;
    late CatalogConflictService conflicts;
    late PendingSyncBloc bloc;
    final retried = <String>[];

    setUp(() async {
      f = await SaleFixture.on(await openTestDb());
      base = await Directory.systemTemp.createTemp('pending_sync_catalog');
      uploads = PendingUploadStore(baseDir: () async => base.path);
      const actor = CatalogActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
      );
      final categories = CategoryService(
        writer: f.writer,
        actor: () => actor,
        uploads: uploads,
      );
      products = ProductService(
        writer: f.writer,
        actor: () => actor,
        uploads: uploads,
        categories: categories,
      );
      conflicts = CatalogConflictService(
        db: f.odb,
        writer: f.writer,
        outbox: f.outbox,
        uploads: uploads,
        scope: () => kScope,
      );
      retried.clear();
      bloc = PendingSyncBloc(
        outbox: f.outbox,
        db: f.odb,
        scope: () => kScope,
        conflicts: conflicts,
        uploads: uploads,
        retryUpload: (entity, id) async {
          retried.add('$entity|$id');
          return true;
        },
      );
      await f.db.insert('categories', {
        'id': kCat,
        'tenant_id': 't1',
        'name': 'Drinks',
        'version': 1,
        'json': jsonEncode({'id': kCat, 'name': 'Drinks', 'is_active': true}),
      });
    });

    tearDown(() async {
      await bloc.close();
      f.notifier.dispose();
      await f.db.close();
      if (base.existsSync()) await base.delete(recursive: true);
    });

    Future<String> rejectedCreate({String? conflictId}) async {
      final pid = await products.create(
        const AddProductRequestDto(
          name: 'Cola',
          price: '10.00',
          category: kCat,
          unit: 'piece',
          sku: 'SKU-1',
          barcode: '111',
          trackInventory: true,
        ),
        initialQuantity: '3',
        shopId: kShop,
      );
      final row = (await f.db.query(
        'outbox',
        where: "entity = 'product' AND op = 'create'",
      )).single;
      await f.db.transaction((txn) async {
        await f.outbox.applyResult(
          txn,
          row['mutation_id'] as String,
          status: OutboxStatus.rejected,
          code: 'conflict_unique',
          message: 'SKU already exists',
          errorEntityId: conflictId,
        );
        await f.outbox.failDependents(txn, pid, scope: kScope);
      });
      return pid;
    }

    Future<void> seedServer() => f.db.insert('products', {
      'id': kServer,
      'name': 'Cola Classic',
      'sku': 'SKU-1',
      'price': '9.00',
      'category_id': kCat,
      'version': 4,
      'json': jsonEncode({
        'id': kServer,
        'name': 'Cola Classic',
        'sku': 'SKU-1',
        'price': '9.00',
        'category': kCat,
        'is_active': true,
      }),
    });

    Future<PendingSyncState> load() async {
      bloc.add(const OnPendingSyncLoad());
      return bloc.stream.firstWhere(
        (s) => s.status == PendingSyncStatus.loaded,
      );
    }

    PendingSyncRow createRow(PendingSyncState s) => s.rows.firstWhere(
      (r) => r.entry.entity == 'product' && r.entry.op == 'create',
    );

    test('a rejected create is labelled by its name and offers merge only '
        'with a conflict_entity_id', () async {
      await rejectedCreate();
      var row = createRow(await load());
      expect(row.label, 'Cola');
      expect(row.isCatalog, isTrue);
      expect(row.canMerge, isFalse);
      expect(row.canEditRetry, isTrue);
      expect(await bloc.previewMerge(row), isNull);
      // The opening stock row was failed by the cascade: plain retry only.
      final stock = (await load()).rows.firstWhere(
        (r) => r.entry.entity == 'stock',
      );
      expect(stock.canEditRetry, isFalse);

      await f.db.update('outbox', {
        'error_entity_id': kServer,
      }, where: "entity = 'product'");
      await seedServer();
      row = createRow(await load());
      expect(row.canMerge, isTrue);
      expect(row.conflictLabel, 'Cola Classic');
    });

    test('merge: preview counts, then everything points at the existing '
        'product', () async {
      final pid = await rejectedCreate(conflictId: kServer);
      await seedServer(); // pulled after the local create
      final row = createRow(await load());
      final preview = (await bloc.previewMerge(row))!;
      expect(preview.requeued, 1); // the opening stock add
      expect(preview.stockRows, 1);

      bloc.add(OnPendingSyncMerge(row.entry.mutationId));
      final s = await bloc.stream.firstWhere(
        (s) => !s.rows.any((r) => r.entry.entity == 'product'),
      );
      expect(s.failure, isNull);
      expect(s.rows.single.entry.entity, 'stock');
      expect(s.rows.single.entry.status, OutboxStatus.pending);
      expect(s.rows.single.entry.payload['product_id'], kServer);
      expect(
        await f.db.query('products', where: 'id = ?', whereArgs: [pid]),
        isEmpty,
      );
    });

    test('M4: a merge starts a sync so the existing row\'s server state '
        'replaces the stand-in copy', () async {
      var syncs = 0;
      final b = PendingSyncBloc(
        outbox: f.outbox,
        db: f.odb,
        scope: () => kScope,
        conflicts: conflicts,
        syncNow: () async => syncs++,
      );
      addTearDown(b.close);
      await rejectedCreate(conflictId: kServer);
      b.add(const OnPendingSyncLoad());
      final s = await b.stream.firstWhere(
        (s) => s.status == PendingSyncStatus.loaded,
      );
      b.add(OnPendingSyncMerge(createRow(s).entry.mutationId));
      await b.stream.firstWhere(
        (s) => !s.rows.any((r) => r.entry.entity == 'product'),
      );
      expect(syncs, 1);
    });

    test('a merge that is no longer possible is reported', () async {
      await rejectedCreate(conflictId: kServer);
      final s = await load();
      await f.db.delete('outbox', where: "entity = 'product'");
      bloc.add(OnPendingSyncMerge(createRow(s).entry.mutationId));
      final after = await bloc.stream.firstWhere((s) => s.failure != null);
      expect(after.failure, PendingSyncFailure.mergeRefused);
    });

    test('discard of a catalog row goes through the conflict service (the '
        'local row goes too)', () async {
      final pid = await rejectedCreate();
      final row = createRow(await load());
      bloc.add(OnPendingSyncDiscardRow(row.entry.mutationId));
      await bloc.stream.firstWhere(
        (s) => !s.rows.any((r) => r.entry.entity == 'product'),
      );
      expect(
        await f.db.query('products', where: 'id = ?', whereArgs: [pid]),
        isEmpty,
      );
    });

    test('I3: a rejected create with a sale waiting on it lists its '
        'dependents, offers no discard, and a discard is refused', () async {
      final pid = await rejectedCreate();
      await f.service().createSale(
        SaleDraft(
          shopId: kShop,
          paymentMethod: 'cash',
          lines: [
            SaleDraftLine.product(
              productId: pid,
              productName: 'Cola',
              quantity: '1',
              unitPrice: '10.00',
            ),
          ],
        ),
      );
      final row = createRow(await load());
      expect(row.dependents, 1, reason: 'the sale; not the opening stock');
      expect(row.canDiscard, isFalse);
      bloc.add(OnPendingSyncDiscardRow(row.entry.mutationId));
      final s = await bloc.stream.firstWhere((s) => s.failure != null);
      expect(s.failure, PendingSyncFailure.discardHasDependents);
      expect(
        await f.db.query('products', where: 'id = ?', whereArgs: [pid]),
        hasLength(1),
      );
    });

    test('M8: a claimed, unanswered create is not discarded', () async {
      await rejectedCreate();
      await f.db.update('outbox', {
        'status': 'pending',
        'claimed_at': '2026-11-16T00:00:00Z',
      }, where: "entity = 'product'");
      final row = createRow(await load());
      bloc.add(OnPendingSyncDiscardRow(row.entry.mutationId));
      final s = await bloc.stream.firstWhere((s) => s.failure != null);
      expect(s.failure, PendingSyncFailure.discardMayBeOnServer);
    });

    test('T5 I4: a rejected sale naming a product that is gone is flagged '
        'and skipped by retry-all; other rows are retried', () async {
      await f.db.transaction(
        (txn) => f.outbox.enqueue(
          txn,
          entity: 'sale',
          op: 'create',
          entityId: 's-gone',
          payload: const {'items': []},
          dependsOn: const ['gone-product'],
          scope: kScope,
        ),
      );
      await f.db.update('outbox', {
        'status': 'rejected',
        'error_code': 'dependency_failed',
        'depends_on_json': jsonEncode(['gone-product']),
      }, where: "entity_id = 's-gone'");
      final pid = await rejectedCreate();
      final s = await load();
      final sale = s.rows.firstWhere((r) => r.entry.entity == 'sale');
      expect(sale.missingDependency, isTrue);
      expect(createRow(s).missingDependency, isFalse);
      bloc.add(const OnPendingSyncRetryAll());
      final after = await bloc.stream.firstWhere(
        (s) => s.rows.any(
          (r) =>
              r.entry.entityId == pid &&
              r.entry.status != OutboxStatus.rejected,
        ),
      );
      expect(
        after.rows.firstWhere((r) => r.entry.entity == 'sale').entry.status,
        OutboxStatus.rejected,
      );
    });

    test('T8/9 concern 5: a row marked local_stale is flagged', () async {
      final pid = await rejectedCreate();
      final r = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [pid],
      )).single;
      await f.db.update(
        'products',
        {
          'json': jsonEncode({
            ...jsonDecode(r['json'] as String) as Map,
            CatalogConflictService.staleKey: true,
          }),
        },
        where: 'id = ?',
        whereArgs: [pid],
      );
      expect(createRow(await load()).stale, isTrue);
    });

    test('edit and retry: queued again only after a saved edit', () async {
      final pid = await rejectedCreate(conflictId: kServer);
      final row = createRow(await load());
      final target = (await bloc.editTarget(row))!;
      expect(target.json!['name'], 'Cola');

      bloc.add(
        OnPendingSyncEditRetry(
          row.entry.mutationId,
          editedAfterSeq: target.seq,
        ),
      );
      final refused = await bloc.stream.firstWhere((s) => s.failure != null);
      expect(refused.failure, PendingSyncFailure.editNotSaved);

      await products.update(pid, const UpdateProductRequestDto(barcode: '222'));
      bloc.add(
        OnPendingSyncEditRetry(
          row.entry.mutationId,
          editedAfterSeq: target.seq,
        ),
      );
      final s = await bloc.stream.firstWhere(
        (s) => s.failure == null && s.status == PendingSyncStatus.loaded,
      );
      final create = createRow(s);
      expect(create.entry.status, OutboxStatus.pending);
      expect(create.entry.payload['barcode'], '222');
    });

    test('failed image uploads are listed and retried', () async {
      final pid = await rejectedCreate();
      await f.db.insert('pending_uploads', {
        'scope': kScope,
        'entity': 'product',
        'entity_id': pid,
        'local_path': '$pid/x',
        'thumbnail_path': '$pid/x',
        'sha256': 'ab',
        'bytes': 2,
        'state': PendingUpload.failed,
        'attempts': 1,
        'last_error': 'Image too large',
        'created_at': '2026-11-16T00:00:00Z',
      });
      final s = await load();
      expect(s.failedUploads.single.label, 'Cola');
      expect(s.failedUploads.single.error, 'Image too large');
      bloc.add(OnPendingSyncRetryUpload('product', pid));
      for (var i = 0; i < 100 && retried.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(retried, ['product|$pid']);
    });
  });

  group('PendingSyncOutboxView (catalog actions)', () {
    setUpAll(() {
      registerFallbackValue(const OnPendingSyncLoad());
      registerFallbackValue(
        PendingSyncRow(
          entry: OutboxEntry(
            mutationId: 'x',
            entity: 'product',
            op: 'create',
            entityId: 'x',
            occurredAt: DateTime.utc(2026),
            payload: const {},
          ),
          label: '',
          otherScope: false,
        ),
      );
    });
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
      String id = 'm1',
      String entity = 'product',
      String op = 'create',
      String? code = 'conflict_unique',
      String? conflict = kServer,
      OutboxStatus status = OutboxStatus.rejected,
      int dependents = 0,
      bool missingDependency = false,
      bool stale = false,
    }) => PendingSyncRow(
      dependents: dependents,
      missingDependency: missingDependency,
      stale: stale,
      entry: OutboxEntry(
        mutationId: id,
        entity: entity,
        op: op,
        entityId: 'local-$id',
        occurredAt: DateTime.utc(2026),
        payload: const {},
        status: status,
        errorCode: code,
        errorMessage: 'SKU already exists',
        errorEntityId: conflict,
        scope: kScope,
      ),
      label: 'Cola',
      otherScope: false,
      conflictLabel: 'Cola Classic',
    );

    Future<void> pump(
      WidgetTester t,
      PendingSyncBloc bloc,
      List<PendingSyncRow> rows, {
      Locale locale = const Locale('en'),
      List<String>? opened,
      List<PendingUploadRow> uploads = const [],
    }) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<PendingSyncBloc>.value(
              value: bloc,
              child: SingleChildScrollView(
                child: PendingSyncOutboxView(
                  rows: rows,
                  failedUploads: uploads,
                  editor: (context, entity, json) async =>
                      opened?.add('$entity:${json['name']}'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
    }

    _MockBloc mock() {
      final b = _MockBloc();
      whenListen(
        b,
        const Stream<PendingSyncState>.empty(),
        initialState: const PendingSyncState(status: PendingSyncStatus.loaded),
      );
      return b;
    }

    testWidgets('rejected create with a conflict id: edit and retry, merge, '
        'discard (en + ar)', (t) async {
      for (final (locale, labels) in [
        (const Locale('en'), ['Edit and retry', 'Merge into existing']),
        (const Locale('ar'), ['تعديل وإعادة المحاولة', 'دمج مع الموجود']),
      ]) {
        await pump(t, mock(), [row()], locale: locale);
        for (final l in labels) {
          expect(find.text(l), findsOneWidget, reason: l);
        }
      }
      await pump(t, mock(), [row()]);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.textContaining('Product · Cola'), findsOneWidget);
    });

    testWidgets('I3: a create others wait on offers no discard and says '
        'why (en + ar)', (t) async {
      await pump(t, mock(), [row(dependents: 2)]);
      expect(find.text('Discard'), findsNothing);
      expect(find.text('Merge into existing'), findsOneWidget);
      expect(
        find.textContaining('2 changes wait on this item'),
        findsOneWidget,
      );
      await pump(t, mock(), [row(dependents: 2)], locale: const Locale('ar'));
      expect(find.textContaining('تغييران ينتظران'), findsOneWidget);
      // An update with the same count is unaffected.
      await pump(t, mock(), [row(op: 'update', dependents: 2)]);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('T5 I4: retry of a row naming a gone item asks first', (
      t,
    ) async {
      final bloc = mock();
      await pump(t, bloc, [
        row(
          entity: 'sale',
          code: 'dependency_failed',
          conflict: null,
          missingDependency: true,
        ),
      ]);
      expect(
        find.text('Refers to an item that is no longer on this phone.'),
        findsOneWidget,
      );
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      verifyNever(() => bloc.add(const OnPendingSyncRetryRow('m1')));
      await t.tap(find.text('Send anyway'));
      await t.pumpAndSettle();
      verify(() => bloc.add(const OnPendingSyncRetryRow('m1'))).called(1);
    });

    testWidgets('a stale row says it is replaced at the next sync', (t) async {
      await pump(t, mock(), [row(op: 'update', stale: true)]);
      expect(find.textContaining('replaced at the next sync'), findsOneWidget);
    });

    testWidgets('merge hidden without conflict_entity_id', (t) async {
      await pump(t, mock(), [row(conflict: null, code: 'limit_exceeded')]);
      expect(find.text('Merge into existing'), findsNothing);
      expect(find.text('Edit and retry'), findsOneWidget);
    });

    testWidgets('a cascade-failed catalog row gets plain retry', (t) async {
      await pump(t, mock(), [
        row(op: 'update', code: 'dependency_failed', conflict: null),
      ]);
      expect(find.text('Edit and retry'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('merge shows a standard confirm with the counts, then '
        'merges', (t) async {
      final bloc = mock();
      when(() => bloc.previewMerge(any())).thenAnswer(
        (_) async => const MergeReport(saleLines: 2, stockRows: 1, requeued: 3),
      );
      await pump(t, bloc, [row()]);
      await t.tap(find.text('Merge into existing'));
      await t.pumpAndSettle();
      expect(find.textContaining('Cola Classic'), findsOneWidget);
      expect(
        find.textContaining('6 records will point to the existing item'),
        findsOneWidget,
      );
      // Fix-wave ruling (M3): stock added, edits and photo dropped.
      expect(
        find.textContaining("added to the existing item's stock"),
        findsOneWidget,
      );
      expect(
        find.textContaining('Its queued edits and its photo are dropped'),
        findsOneWidget,
      );
      expect(find.textContaining('The existing item is deleted'), findsNothing);
      // Confirm button of the sheet carries the action label.
      await t.tap(find.text('Merge into existing').last);
      await t.pumpAndSettle();
      verify(() => bloc.add(const OnPendingSyncMerge('m1'))).called(1);
    });

    testWidgets('M2: merging into a deleted item warns', (t) async {
      final bloc = mock();
      when(() => bloc.previewMerge(any())).thenAnswer(
        (_) async => const MergeReport(saleLines: 1, targetInactive: true),
      );
      await pump(t, bloc, [row()]);
      await t.tap(find.text('Merge into existing'));
      await t.pumpAndSettle();
      expect(
        find.textContaining('The existing item is deleted'),
        findsOneWidget,
      );
    });

    testWidgets('edit and retry opens the editor, then retries with the '
        'seq taken before', (t) async {
      final bloc = mock();
      when(() => bloc.editTarget(any())).thenAnswer(
        (_) async => (seq: 41, json: <String, dynamic>{'name': 'Cola'}),
      );
      final opened = <String>[];
      await pump(t, bloc, [row()], opened: opened);
      await t.tap(find.text('Edit and retry'));
      await t.pumpAndSettle();
      expect(opened, ['product:Cola']);
      verify(
        () => bloc.add(const OnPendingSyncEditRetry('m1', editedAfterSeq: 41)),
      ).called(1);
    });

    testWidgets('a failed upload row retries', (t) async {
      final bloc = mock();
      await pump(
        t,
        bloc,
        const [],
        uploads: const [
          PendingUploadRow(
            entity: 'product',
            entityId: 'p1',
            label: 'Cola',
            error: 'Image too large',
          ),
        ],
      );
      expect(find.text('Image upload failed'), findsOneWidget);
      await t.tap(find.text('Retry'));
      verify(
        () => bloc.add(const OnPendingSyncRetryUpload('product', 'p1')),
      ).called(1);
    });
  });
}
