import 'appliers/inbound_applier.dart';
import 'appliers/sale_applier.dart';
import 'appliers/stock_applier.dart';
import 'change_applier.dart';

/// The ONE list of change appliers the sync engine runs with. Shared by the
/// app's DI and the background worker so both apply pulled changes and push
/// results identically. Features moving onto the sync core add theirs here.
ChangeApplierRegistry buildSyncAppliers() => ChangeApplierRegistry()
  ..register(StockApplier())
  ..register(SaleApplier())
  ..register(InboundApplier());

/// Every local table the appliers write (what a sync run outside this
/// isolate may have changed).
Set<String> syncedLocalTables(ChangeApplierRegistry registry) => {
  for (final a in registry.all) ...a.tables,
};
