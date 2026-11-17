import 'synced_entity_applier.dart';

/// Server notification -> `synced_entities` (no legacy reader).
class NotificationApplier extends SyncedEntityApplier {
  NotificationApplier({super.store});

  @override
  String get entity => 'notification';

  @override
  String? validate(Map<String, dynamic> d) {
    if (d['title'] is! String || d['body'] is! String) return 'malformed';
    return null;
  }
}
