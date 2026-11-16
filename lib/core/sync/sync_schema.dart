import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import 'decimal3.dart';

class SyncTables {
  SyncTables._();

  static const String outbox = 'outbox';
  static const String syncState = 'sync_state';
}

class SyncSchema {
  SyncSchema._();

  static Future<void> createAll(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SyncTables.outbox} (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        mutation_id TEXT UNIQUE NOT NULL,
        entity TEXT NOT NULL,
        op TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        depends_on_entity_id TEXT,
        base_version INTEGER,
        occurred_at TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_attempt_at TEXT,
        lease_until TEXT,
        error_code TEXT,
        error_message TEXT,
        created_at TEXT NOT NULL,
        scope TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_status_seq '
      'ON ${SyncTables.outbox}(status, seq)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_entity '
      'ON ${SyncTables.outbox}(entity, entity_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_entity_seq '
      'ON ${SyncTables.outbox}(entity_id, seq)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_scope_status_seq '
      'ON ${SyncTables.outbox}(scope, status, seq)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SyncTables.syncState} (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// v7 -> v8: exact server base of a stock row (decimal string). `quantity`
  /// stays the displayed value (base + this device's pending deltas).
  /// Idempotent; existing rows are backfilled from `quantity`.
  static Future<void> addStockBaseQuantity(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(stock)');
    if (cols.any((c) => c['name'] == 'base_quantity')) return;
    await db.execute(
      "ALTER TABLE stock ADD COLUMN base_quantity TEXT NOT NULL DEFAULT '0'",
    );
    final rows = await db.rawQuery(
      'SELECT id, quantity FROM stock WHERE quantity != 0',
    );
    for (final r in rows) {
      final units = Decimal3.tryParse(r['quantity']);
      if (units == null) continue;
      await db.update(
        'stock',
        {'base_quantity': Decimal3.format(units)},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
  }

  /// v6 -> v7: adds the owner scope to an existing outbox. Rows written
  /// before this have scope '' and are never pushed by any session.
  static Future<void> addOutboxScope(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(${SyncTables.outbox})');
    if (!cols.any((c) => c['name'] == 'scope')) {
      await db.execute(
        "ALTER TABLE ${SyncTables.outbox} "
        "ADD COLUMN scope TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_scope_status_seq '
      'ON ${SyncTables.outbox}(scope, status, seq)',
    );
    final legacy = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM ${SyncTables.outbox} WHERE scope = ''",
    );
    final n = (legacy.first['c'] as int?) ?? 0;
    if (n > 0) {
      developer.log(
        'outbox v7 upgrade: $n row(s) without an owner scope will not be '
        'pushed by any session',
        name: 'SyncSchema',
      );
    }
  }
}
