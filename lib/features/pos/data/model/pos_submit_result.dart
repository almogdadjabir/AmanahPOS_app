class PosSubmitResult {
  final bool synced;
  final bool queued;
  final String? saleId;
  final String? clientSaleId;

  const PosSubmitResult._({
    required this.synced,
    required this.queued,
    this.saleId,
    this.clientSaleId,
  });

  factory PosSubmitResult.synced(String? saleId) {
    return PosSubmitResult._(
      synced: true,
      queued: false,
      saleId: saleId,
    );
  }

  factory PosSubmitResult.offlineQueued(String clientSaleId) {
    return PosSubmitResult._(
      synced: false,
      queued: true,
      clientSaleId: clientSaleId,
    );
  }
}