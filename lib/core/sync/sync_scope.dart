/// The signed-in `userId|tenantId` scope that outbox rows and sync progress
/// belong to. Set by `SyncCoordinator` when a session becomes ready and
/// cleared on logout; local writers read it to tag the rows they enqueue.
class SyncScope {
  SyncScope._();

  static String? current;
}
