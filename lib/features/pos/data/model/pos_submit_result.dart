class PosSubmitResult {
  final bool synced;
  final bool queued;
  final String? saleId;
  final String clientSaleId;
  final String? receiptNumber;

  // Server-computed tax snapshot (docs/TAX_SUPPORT.md §3). Null when the
  // sale was queued offline — callers fall back to the local preview.
  final String? taxAmount;
  final String? taxRate;
  final bool? taxInclusive;
  final String? netAmount;

  const PosSubmitResult._({
    required this.synced,
    required this.queued,
    required this.clientSaleId,
    this.saleId,
    this.receiptNumber,
    this.taxAmount,
    this.taxRate,
    this.taxInclusive,
    this.netAmount,
  });

  factory PosSubmitResult.synced({
    required String clientSaleId,
    String? saleId,
    String? receiptNumber,
    String? taxAmount,
    String? taxRate,
    bool? taxInclusive,
    String? netAmount,
  }) {
    return PosSubmitResult._(
      synced: true,
      queued: false,
      clientSaleId: clientSaleId,
      saleId: saleId,
      receiptNumber: receiptNumber,
      taxAmount: taxAmount,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
      netAmount: netAmount,
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
