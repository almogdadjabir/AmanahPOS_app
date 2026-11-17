import 'dart:convert';
import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import 'decimal3.dart';

class SyncTables {
  SyncTables._();

  static const String outbox = 'outbox';
  static const String syncState = 'sync_state';
  static const String pendingUploads = 'pending_uploads';
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

  /// v13 -> v14: `depends_on_json` = JSON array of the entity ids a row
  /// waits on (NULL = none). Replaces the single `depends_on_entity_id`,
  /// which stays in the table unused (SQLite cannot drop it cheaply).
  /// Idempotent; a row with the legacy column set and no list yet is
  /// backfilled to a one-element list.
  static Future<void> addOutboxDependsOnList(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(${SyncTables.outbox})');
    if (!cols.any((c) => c['name'] == 'depends_on_json')) {
      await db.execute(
        'ALTER TABLE ${SyncTables.outbox} ADD COLUMN depends_on_json TEXT',
      );
    }
    final legacy = await db.rawQuery(
      'SELECT seq, depends_on_entity_id FROM ${SyncTables.outbox} '
      'WHERE depends_on_json IS NULL AND depends_on_entity_id IS NOT NULL '
      "AND depends_on_entity_id != ''",
    );
    for (final r in legacy) {
      await db.update(
        SyncTables.outbox,
        {
          'depends_on_json': jsonEncode([r['depends_on_entity_id']]),
        },
        where: 'seq = ?',
        whereArgs: [r['seq']],
      );
    }
  }

  /// v14 (Phase 3, Task 5): `outbox.error_entity_id` = the server's
  /// `conflict_entity_id` of a `conflict_unique` rejection (read by the
  /// pending-sync "Merge into existing" action). Idempotent.
  static Future<void> addOutboxErrorEntityId(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(${SyncTables.outbox})');
    if (cols.any((c) => c['name'] == 'error_entity_id')) return;
    await db.execute(
      'ALTER TABLE ${SyncTables.outbox} ADD COLUMN error_entity_id TEXT',
    );
  }

  /// v14 (Phase 3, Task 5): `outbox.claimed_at` = when a sync run FIRST
  /// claimed the row (sticky; never cleared). A row that was ever claimed
  /// may have reached the server even if it is `pending` again (lost
  /// response, crash after send), so a local delete must not drop its
  /// create (`CatalogSupport.dropNeverSentCreate`). Idempotent.
  /// v14 (fix-wave M9): `failed_by_entity_id`, the entity whose failed
  /// create rejected this row `dependency_failed` (locally cascaded, or the
  /// BE's own in-batch failure). Revival on a retry / merge of that create
  /// matches this column, not the error text. Idempotent.
  static Future<void> addOutboxFailedBy(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(${SyncTables.outbox})');
    if (cols.any((c) => c['name'] == 'failed_by_entity_id')) return;
    await db.execute(
      'ALTER TABLE ${SyncTables.outbox} ADD COLUMN failed_by_entity_id TEXT',
    );
  }

  static Future<void> addOutboxClaimedAt(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(${SyncTables.outbox})');
    if (cols.any((c) => c['name'] == 'claimed_at')) return;
    await db.execute(
      'ALTER TABLE ${SyncTables.outbox} ADD COLUMN claimed_at TEXT',
    );
  }

  /// v14 (Phase 3): one row per entity whose picked image still has to be
  /// uploaded (`PendingUploadStore`). `sha256` is of the staged bytes (the
  /// uploaded bytes, ruling T1-a); `local_path`/`thumbnail_path` are
  /// RELATIVE to `<appSupport>/pending_images` (same file: no encoder
  /// dependency); `scope` is the owning sync scope (readers filter on it).
  /// User data like the outbox: never wiped by logout or a business switch.
  /// Idempotent.
  static Future<void> createPendingUploads(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SyncTables.pendingUploads} (
        scope TEXT NOT NULL DEFAULT '',
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        thumbnail_path TEXT,
        sha256 TEXT NOT NULL,
        bytes INTEGER NOT NULL,
        state TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_attempt_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL,
        PRIMARY KEY(entity, entity_id)
      )
    ''');
    // A table created by an earlier v14 build has no scope column yet.
    final cols = await db.rawQuery(
      'PRAGMA table_info(${SyncTables.pendingUploads})',
    );
    if (!cols.any((c) => c['name'] == 'scope')) {
      await db.execute(
        'ALTER TABLE ${SyncTables.pendingUploads} '
        "ADD COLUMN scope TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.execute('DROP INDEX IF EXISTS idx_pending_uploads_due');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_uploads_scope_due '
      'ON ${SyncTables.pendingUploads}(scope, state, next_attempt_at)',
    );
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
