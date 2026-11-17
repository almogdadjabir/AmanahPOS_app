import 'synced_entity_applier.dart';
import 'applier_support.dart';

/// Server expiry_batch -> `synced_entities` (no legacy reader).
class ExpiryBatchApplier extends SyncedEntityApplier {
  ExpiryBatchApplier({super.store});

  @override
  String get entity => 'expiry_batch';

  @override
  String? validate(Map<String, dynamic> d) {
    if (d['product'] is! String || d['shop'] is! String) return 'bad refs';
    if (!decimalOk(d['quantity'])) return 'bad quantity';
    return null;
  }
}
