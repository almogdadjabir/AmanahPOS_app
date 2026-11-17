import 'synced_entity_applier.dart';

/// Server user -> `synced_entities` (no legacy reader).
class UserApplier extends SyncedEntityApplier {
  UserApplier({super.store});

  @override
  String get entity => 'user';

  @override
  bool get versioned => true;

  @override
  String? validate(Map<String, dynamic> d) {
    if (d['phone'] is! String || d['role'] is! String) return 'malformed';
    return null;
  }
}
