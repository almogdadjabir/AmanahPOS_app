import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:sqflite/sqflite.dart';

const kShop = '11111111-1111-4111-8111-111111111111';
const kP1 = '22222222-2222-4222-8222-222222222222';
const kP2 = '33333333-3333-4333-8333-333333333333';
const kScope = 'u1|t1';
const kCashier = '55555555-5555-4555-8555-555555555555';
const kDevice = 'abcd1234-0000-4000-8000-000000000000';

/// One device: real in-memory DB, LocalWriter, outbox, state and service.
class SaleFixture {
  SaleFixture._(this.odb, this.db);

  final OfflineDb odb;
  final Database db;
  final notifier = DbChangeNotifier();
  late final OutboxStore outbox = OutboxStore(odb);
  late final SyncStateStore state = SyncStateStore(odb);
  String? scope = kScope;

  /// Cashier id handed to the service (a real user UUID by default).
  String? cashier = kCashier;
  late final LocalWriter writer = LocalWriter(
    odb,
    outbox,
    notifier,
    scopeProvider: () => scope,
  );

  DateTime clock = DateTime.utc(2026, 11, 16, 9, 30);

  SaleService service({Future<void> Function(String stage)? debugHook}) =>
      SaleService(
        writer: writer,
        state: state,
        cashierId: () => cashier,
        now: () => clock,
        debugHook: debugHook,
      );

  static Future<SaleFixture> on(OfflineDb odb) async {
    final f = SaleFixture._(odb, await odb.database);
    await f.db.insert('sync_state', {
      'key': 'device_id',
      'value': kDevice,
      'updated_at': '2026-01-01T00:00:00Z',
    });
    await f.seedProduct(kP1, 'Tea', base: '10');
    await f.seedProduct(kP2, 'Sugar', base: '5');
    return f;
  }

  Future<void> seedProduct(String id, String name, {String? base}) async {
    await db.insert('products', {
      'id': id,
      'name': name,
      'stock_level': 0.0,
      'json': '{"id":"$id","name":"$name"}',
    });
    if (base != null) {
      await const StockLocalStore().setBase(db, id, kShop, base);
    }
  }

  /// A row in the current business's `shops` table (local sale queries
  /// only show sales of shops listed there).
  Future<void> seedShop(String id, {String? businessId}) => db.insert('shops', {
    'id': id,
    'business_id': businessId,
    'json': '{"id":"$id"}',
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String, Object?>> stock(String productId) async => (await db.query(
    'stock',
    where: 'product_id = ? AND shop_id = ?',
    whereArgs: [productId, kShop],
  )).single;

  Future<double> level(String productId) async =>
      ((await db.query(
                'products',
                where: 'id = ?',
                whereArgs: [productId],
              )).single['stock_level']
              as num)
          .toDouble();

  Future<int> count(String table) async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table'))!;
}
