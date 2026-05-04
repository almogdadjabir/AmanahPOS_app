class OfflineSaleSyncResult {
  final String clientSaleId;
  final String status;
  final String? serverSaleId;
  final String? message;

  OfflineSaleSyncResult({
    required this.clientSaleId,
    required this.status,
    this.serverSaleId,
    this.message,
  });

  factory OfflineSaleSyncResult.fromJson(Map<String, dynamic> json) {
    return OfflineSaleSyncResult(
      clientSaleId: json['client_sale_id'] ?? '',
      status: json['status'] ?? 'failed',
      serverSaleId: json['server_sale_id'],
      message: json['message'],
    );
  }
}