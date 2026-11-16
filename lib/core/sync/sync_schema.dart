import 'package:sqflite/sqflite.dart';

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
        created_at TEXT NOT NULL
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SyncTables.syncState} (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
