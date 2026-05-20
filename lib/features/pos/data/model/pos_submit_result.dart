class PosSubmitResult {
  final bool synced;
  final bool queued;
  final String? saleId;
  final String clientSaleId;
  final String? receiptNumber;

  const PosSubmitResult._({
    required this.synced,
    required this.queued,
    required this.clientSaleId,
    this.saleId,
    this.receiptNumber,
  });

  factory PosSubmitResult.synced({
    required String clientSaleId,
    String? saleId,
    String? receiptNumber,
  }) {
    return PosSubmitResult._(
      synced: true,
      queued: false,
      clientSaleId: clientSaleId,
      saleId: saleId,
      receiptNumber: receiptNumber,
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
