class PosSubmitResult {
  final bool synced;
  final bool queued;

  /// Saved to the local sales tables + outbox (sync engine path). The sale
  /// is complete for the UI; [receiptNumber] is the local `L-...` number
  /// and the tax/net values are the exact local ones (equal to the BE's).
  final bool local;
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
    this.local = false,
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

  factory PosSubmitResult.localSaved({
    required String saleId,
    required String? receiptNumber,
    required String taxAmount,
    required String taxRate,
    required bool taxInclusive,
    required String netAmount,
  }) {
    return PosSubmitResult._(
      synced: false,
      queued: false,
      local: true,
      clientSaleId: saleId,
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
