import 'synced_entity_applier.dart';

/// Server bankak_account -> `synced_entities` (no legacy reader).
class BankakAccountApplier extends SyncedEntityApplier {
  BankakAccountApplier({super.store});

  @override
  String get entity => 'bankak_account';

  @override
  String? validate(Map<String, dynamic> d) {
    if (d['account_number'] is! String) return 'bad account_number';
    return null;
  }
}
