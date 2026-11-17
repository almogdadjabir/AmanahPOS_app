import 'synced_entity_applier.dart';

/// Server subscription -> `synced_entities` (no legacy reader).
class SubscriptionApplier extends SyncedEntityApplier {
  SubscriptionApplier({super.store});

  @override
  String get entity => 'subscription';

  @override
  String? validate(Map<String, dynamic> d) {
    if (d['plan'] is! Map) return 'bad plan';
    if (d['is_active'] is! bool) return 'bad is_active';
    return null;
  }
}
