// FakeSyncServer catalog semantics (Task 5): mirrors amanaPOS-be
// apps/sync/handlers.py catalog_create/update/delete, services._apply_one
// (cashier gate, in-batch dependency_failed) and the image PUT view.
import 'dart:convert';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/transport/image_upload_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

void main() {
  late FakeSyncServer s;
  var n = 0;

  setUp(() {
    s = FakeSyncServer(now: () => DateTime.utc(2026, 11, 17));
    n = 0;
  });

  OutboxEntry m(
    String entity,
    String op,
    String id,
    Map<String, dynamic> payload, {
    int? baseVersion,
    String? mid,
  }) => OutboxEntry(
    seq: ++n,
    mutationId: mid ?? 'm$n',
    entity: entity,
    op: op,
    entityId: id,
    baseVersion: baseVersion,
    occurredAt: DateTime.utc(2026, 11, 17),
    payload: payload,
  );

  Future<List<PushResult>> push(
    List<OutboxEntry> ms, {
    FakeSyncServer? on,
  }) async => (await (on ?? s).push(
    deviceId: 'd',
    appVersion: '1',
    mutations: ms,
    scope: 'u1|t1',
  )).results;

  test('create uses the client id; replay is duplicate; an existing id is '
      'conflict_unique naming itself', () async {
    final a = m('product', 'create', 'p1', {
      'name': 'A',
      'price': '1',
      'image_pending': true,
      'id': 'p1',
    });
    final r = (await push([a])).single;
    expect([r.status, r.entityId, r.version], [PushStatus.applied, 'p1', 1]);
    expect(r.serverSeq, isNotNull);
    expect(s.tables['product']!['p1']!['is_active'], isTrue);
    expect(s.tables['product']!['p1']!.containsKey('image_pending'), isFalse);
    expect((await push([a])).single.status, PushStatus.duplicate);
    final again = (await push([
      m('product', 'create', 'p1', {'name': 'B'}),
    ])).single;
    expect([again.code, again.conflictEntityId], ['conflict_unique', 'p1']);
  });

  test('tenant uniqueness: product sku/barcode (inactive rows too), category '
      'name per parent, vendor name case-insensitive', () async {
    await push([
      m('product', 'create', 'p1', {'name': 'A', 'sku': 'S1', 'barcode': 'B1'}),
      m('category', 'create', 'c1', {'name': 'Drinks'}),
      m('category', 'create', 'c2', {'name': 'Cold', 'parent': 'c1'}),
      m('vendor', 'create', 'v1', {'name': 'Acme'}),
    ]);
    await push([m('product', 'delete', 'p1', {})]);
    final r = await push([
      m('product', 'create', 'p2', {'name': 'B', 'sku': ' S1 '}),
      m('product', 'create', 'p3', {'name': 'C', 'barcode': 'B1'}),
      m('product', 'create', 'p4', {'name': 'D', 'barcode': ''}),
      m('category', 'create', 'c3', {'name': 'Drinks'}),
      m('category', 'create', 'c4', {'name': 'Cold'}), // other parent: ok
      m('category', 'create', 'c5', {'name': 'Cold', 'parent': 'c1'}),
      m('vendor', 'create', 'v2', {'name': ' ACME '}),
    ]);
    expect(r.map((x) => x.code), [
      'conflict_unique',
      'conflict_unique',
      null,
      'conflict_unique',
      null,
      'conflict_unique',
      'conflict_unique',
    ]);
    expect(r.map((x) => x.conflictEntityId), [
      'p1',
      'p1',
      null,
      'c1',
      null,
      'c2',
      'v1',
    ]);
    expect(r[0].errors, {
      'sku': ['Already exists.'],
    });
    expect(r[0].serverState!['id'], 'p1');
    // An update colliding with another row (not itself) is refused too;
    // in the same push a later edit of that row fails with it (BE
    // failed_ids), in a later push it is applied.
    final u = await push([
      m('product', 'update', 'p4', {'barcode': 'B1'}, baseVersion: 1),
      m('product', 'update', 'p4', {'name': 'D2'}, baseVersion: 1),
    ]);
    expect(u.map((x) => x.code), ['conflict_unique', 'dependency_failed']);
    expect(
      (await push([
        m('product', 'update', 'p4', {'name': 'D2'}, baseVersion: 1),
      ])).single.status,
      PushStatus.applied,
    );
  });

  test('update with a stale base_version is applied field-wise and returns '
      'merged + server_state', () async {
    await push([
      m('product', 'create', 'p1', {'name': 'A', 'price': '1'}),
    ]);
    await push([
      m('product', 'update', 'p1', {'price': '2'}, baseVersion: 1),
    ]);
    final r = (await push([
      m('product', 'update', 'p1', {'name': 'B'}, baseVersion: 1),
    ])).single;
    expect(r.status, PushStatus.applied);
    expect(r.version, 3);
    expect(r.merged, isTrue);
    expect(r.serverState!['name'], 'B');
    expect(r.serverState!['price'], '2');
    final fresh = (await push([
      m('product', 'update', 'p1', {'name': 'C'}, baseVersion: 3),
    ])).single;
    expect(fresh.merged, isFalse);
    expect(fresh.serverState, isNull);
  });

  test('delete = is_active false + a tombstone change row; update of a '
      'deleted row is entity_deleted; a second delete is applied', () async {
    await push([
      m('vendor', 'create', 'v1', {'name': 'A'}),
    ]);
    final d = (await push([m('vendor', 'delete', 'v1', {})])).single;
    expect([d.status, d.version], [PushStatus.applied, 2]);
    expect(s.tables['vendor']!['v1']!['is_active'], isFalse);
    expect(s.feed.last.op, 'delete');
    expect(s.feed.last.version, 2);
    final u = (await push([
      m('vendor', 'update', 'v1', {'name': 'B'}, baseVersion: 2),
    ])).single;
    expect(u.code, 'entity_deleted');
    expect(u.serverState!['is_active'], isFalse);
    final feedLen = s.feed.length;
    final d2 = (await push([m('vendor', 'delete', 'v1', {})])).single;
    expect(d2.status, PushStatus.applied);
    expect(s.feed.length, feedLen, reason: 'idempotent: no new change row');
    expect(
      (await push([m('vendor', 'delete', 'nope', {})])).single.code,
      'not_found',
    );
    expect(
      (await push([
        m('vendor', 'update', 'nope', {'name': 'x'}),
      ])).single.code,
      'not_found',
    );
    // Bootstrap still serves the inactive row (history stays resolvable).
    final manifest = await s.bootstrapManifest(scope: 'u1|t1');
    final page = await s.bootstrapPage(
      entity: 'vendor',
      snapshotCursor: manifest.snapshotCursor,
      scope: 'u1|t1',
    );
    expect(page.items.single['is_active'], isFalse);
  });

  test('limit_exceeded knob counts active products', () async {
    s.productLimit = 1;
    final r = await push([
      m('product', 'create', 'p1', {'name': 'A'}),
      m('product', 'create', 'p2', {'name': 'B'}),
    ]);
    expect(r.map((x) => x.code), [null, 'limit_exceeded']);
    await push([m('product', 'delete', 'p1', {})]);
    expect(
      (await push([
        m('product', 'create', 'p3', {'name': 'C'}),
      ])).single.status,
      PushStatus.applied,
    );
  });

  test(
    'forbidden for a cashier actor on catalog writes; sales still pass',
    () async {
      final cashier = s.forDevice('c')..role = 'cashier';
      final r = await push([
        m('category', 'create', 'c1', {'name': 'A'}),
        m('vendor', 'create', 'v1', {'name': 'A'}),
        m('customer', 'create', 'k1', {'name': 'A'}),
        m('stock', 'add', 's1', {
          'product_id': 'p',
          'shop_id': 'sh',
          'delta': '1',
        }),
      ], on: cashier);
      expect(r.map((x) => x.code), ['forbidden', 'forbidden', null, null]);
      // per view: the owner's view is unaffected
      expect(
        (await push([
          m('vendor', 'create', 'v1', {'name': 'A'}),
        ])).single.status,
        PushStatus.applied,
      );
    },
  );

  test('in-batch seq order; dependents of a rejected create are '
      'dependency_failed with depends_on', () async {
    await push([
      m('product', 'create', 'p0', {'name': 'X', 'barcode': 'B'}),
    ]);
    // Sent out of order: the server sorts by seq.
    final create = m('product', 'create', 'p1', {'name': 'Y', 'barcode': 'B'});
    final edit = m('product', 'update', 'p1', {'name': 'Z'});
    final sale = m('sale', 'create', 'sale1', {
      'shop': 'sh',
      'items': [
        {'product_id': 'p1', 'quantity': '1', 'unit_price': '1'},
      ],
    });
    final r = await push([sale, edit, create]);
    expect(r.map((x) => x.mutationId), [
      create.mutationId,
      edit.mutationId,
      sale.mutationId,
    ]);
    expect(r.map((x) => x.code), [
      'conflict_unique',
      'dependency_failed',
      'dependency_failed',
    ]);
    expect(r[1].dependsOn, ['p1']);
    expect(r[2].dependsOn, ['p1']);
    // A rejected category create fails a product create naming it.
    final c = await push([
      m('category', 'create', 'c1', {'name': 'K'}),
      m('category', 'create', 'c2', {'name': 'K'}),
      m('product', 'create', 'p9', {'name': 'P', 'category': 'c2'}),
    ]);
    expect(c.map((x) => x.code), [
      null,
      'conflict_unique',
      'dependency_failed',
    ]);
  });

  test(
    'a rejected mutation replayed is re-evaluated (BE deviation 6)',
    () async {
      await push([
        m('vendor', 'create', 'v0', {'name': 'Acme'}),
      ]);
      final mine = m('vendor', 'create', 'v1', {'name': 'Acme'}, mid: 'mine');
      expect((await push([mine])).single.code, 'conflict_unique');
      expect((await push([mine])).single.code, 'conflict_unique');
      await push([
        m('vendor', 'update', 'v0', {'name': 'Other'}),
      ]);
      expect((await push([mine])).single.status, PushStatus.applied);
    },
  );

  test('strict catalog: a sale line of an unknown product is kept with '
      'product NULL + product_missing', () async {
    s.strictCatalog = true;
    const shop = 'e0000000-0000-4000-8000-000000000001';
    const prod = 'f0000000-0000-4000-8000-000000000009';
    const sale = 'a0000000-0000-4000-8000-000000000001';
    final r = (await push([
      m('sale', 'create', sale, {
        'shop': shop,
        'items': [
          {
            'product_id': prod,
            'quantity': '1',
            'unit_price': '2',
            'product_name': 'Gone',
          },
        ],
      }),
    ])).single;
    expect(r.status, PushStatus.applied);
    expect(r.warnings, contains('product_missing'));
    final item = (s.tables['sale']![sale]!['items'] as List).single as Map;
    expect(item['product'], isNull);
    expect(item['product_name'], 'Gone');
  });

  group('PUT image', () {
    final bytes = utf8.encode('fake-image-bytes');
    final sha = sha256.convert(bytes).toString();

    test('idempotent by X-Content-SHA256; sets image_hash = sha256 of the '
        'uploaded bytes', () async {
      await push([
        m('product', 'create', 'p1', {'name': 'A'}),
      ]);
      expect(s, isA<ImageUploadTransport>());
      final t = s;
      final r1 = await t.putImage(
        entity: 'product',
        entityId: 'p1',
        bytes: bytes,
        sha256: sha,
        scope: 'u1|t1',
      );
      expect(r1.imageHash, sha);
      expect(r1.image, isNotNull);
      expect(r1.thumbnailUrl, isNotNull);
      expect(r1.version, 2);
      expect(r1.unchanged, isFalse);
      expect(s.tables['product']!['p1']!['image_hash'], sha);
      expect(s.feed.last.data!['image_hash'], sha);

      // Lost response, then retry: still one stored image, same version.
      s.dropImageResponseAfterApply = 1;
      await expectLater(
        t.putImage(
          entity: 'product',
          entityId: 'p1',
          bytes: bytes,
          sha256: sha,
          scope: 'u1|t1',
        ),
        throwsA(isA<SyncTransportException>()),
      );
      final r2 = await t.putImage(
        entity: 'product',
        entityId: 'p1',
        bytes: bytes,
        sha256: sha,
        scope: 'u1|t1',
      );
      expect(r2.unchanged, isTrue);
      expect(r2.version, 2);
      expect(s.imageStores, 1);
    });

    test('hash mismatch -> 400 hash_mismatch; unknown -> 404; cashier -> 403; '
        'category endpoint', () async {
      await push([
        m('category', 'create', 'c1', {'name': 'A'}),
      ]);
      Future<Object?> err(
        String entity,
        String id,
        String hash, [
        FakeSyncServer? on,
      ]) async {
        try {
          await (on ?? s).putImage(
            entity: entity,
            entityId: id,
            bytes: bytes,
            sha256: hash,
            scope: 'u1|t1',
          );
          return null;
        } on SyncTransportException catch (e) {
          return '${e.httpStatus} ${e.code}';
        }
      }

      expect(await err('category', 'c1', 'deadbeef'), '400 hash_mismatch');
      expect(await err('product', 'nope', sha), '404 not_found');
      expect(
        await err('category', 'c1', sha, s.forDevice('x')..role = 'cashier'),
        '403 forbidden',
      );
      expect(await err('category', 'c1', sha), isNull);
      expect(s.tables['category']!['c1']!['image_hash'], sha);
    });
  });
}
