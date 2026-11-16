import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens an in-memory [OfflineDb] with the full schema for tests.
Future<OfflineDb> openTestDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      singleInstance: false,
      version: OfflineDb.schemaVersion,
      onConfigure: OfflineDb.onConfigure,
      onCreate: OfflineDb.onCreate,
    ),
  );
  return OfflineDb.forTesting(db);
}
