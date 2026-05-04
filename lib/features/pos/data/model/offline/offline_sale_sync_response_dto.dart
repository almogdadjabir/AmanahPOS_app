class OfflineSaleSyncResponseDto {
  final bool success;
  final List<OfflineSaleSyncResult> results;

  const OfflineSaleSyncResponseDto({
    required this.success,
    required this.results,
  });

  factory OfflineSaleSyncResponseDto.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return OfflineSaleSyncResponseDto(
      success: map['success'] == true,
      results: (map['results'] as List<dynamic>? ?? const [])
          .map(
            (item) => OfflineSaleSyncResult.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList(),
    );
  }
}

class OfflineSaleSyncResult {
  final String clientSaleId;
  final String status;
  final String? serverSaleId;
  final String? message;

  const OfflineSaleSyncResult({
    required this.clientSaleId,
    required this.status,
    this.serverSaleId,
    this.message,
  });

  factory OfflineSaleSyncResult.fromJson(Map<String, dynamic> json) {
    return OfflineSaleSyncResult(
      clientSaleId: json['client_sale_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'failed',
      serverSaleId: json['server_sale_id']?.toString(),
      message: json['message']?.toString(),
    );
  }
}