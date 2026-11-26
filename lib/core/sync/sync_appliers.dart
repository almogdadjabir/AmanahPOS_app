import 'appliers/bankak_account_applier.dart';
import 'appliers/business_applier.dart';
import 'appliers/category_applier.dart';
import 'appliers/customer_applier.dart';
import 'appliers/expiry_batch_applier.dart';
import 'appliers/inbound_applier.dart';
import 'appliers/product_applier.dart';
import 'appliers/refund_applier.dart';
import 'appliers/sale_applier.dart';
import 'appliers/notification_applier.dart';
import 'appliers/shift_applier.dart';
import 'appliers/shop_applier.dart';
import 'appliers/stock_applier.dart';
import 'appliers/subscription_applier.dart';
import 'appliers/user_applier.dart';
import 'appliers/vendor_applier.dart';
import 'change_applier.dart';

/// Entities that are pushed but not in the pull feed or the bootstrap yet
/// (docs/BE_GAPS_PARITY.md G5). Their appliers only record push results.
const Set<String> pushOnlyEntities = {'shift', 'cash_movement'};

/// The ONE list of change appliers the sync engine runs with. Shared by the
/// app's DI and the background worker so both apply pulled changes and push
/// results identically. Features moving onto the sync core add theirs here.
///
/// [scopeProvider] gives the `userId|tenantId` the appliers write under
/// (shop `business_id`, category `tenant_id`); defaults to
/// `SyncScope.current`. The background worker passes its own scope.
ChangeApplierRegistry buildSyncAppliers({String? Function()? scopeProvider}) =>
    ChangeApplierRegistry()
      ..register(BusinessApplier())
      ..register(ShopApplier(scopeProvider: scopeProvider))
      ..register(CategoryApplier(scopeProvider: scopeProvider))
      ..register(ProductApplier())
      ..register(StockApplier())
      ..register(SaleApplier())
      ..register(RefundApplier())
      ..register(InboundApplier())
      ..register(CustomerApplier())
      ..register(VendorApplier())
      ..register(ExpiryBatchApplier())
      ..register(UserApplier())
      ..register(SubscriptionApplier())
      ..register(NotificationApplier())
      ..register(BankakAccountApplier())
      ..register(ShiftApplier.shift())
      ..register(ShiftApplier.cashMovement());

/// Every local table the appliers write (what a sync run outside this
/// isolate may have changed).
Set<String> syncedLocalTables(ChangeApplierRegistry registry) => {
  for (final a in registry.all) ...a.tables,
};
