// lib/features/inventory/data/models/responses/expiry_alert_response_dto.dart
//
// Matches the actual API response:
// GET /api/v1/inventory/expiry-alerts/
// {
//   "success": true,
//   "data": {
//     "expiring_soon": [ ...ExpiryAlertData ],
//     "expired":       [ ...ExpiryAlertData ]
//   }
// }

class ExpiryAlertResponseDto {
  final bool?                  success;
  final List<ExpiryAlertData>  expiringSoon;
  final List<ExpiryAlertData>  expired;

  const ExpiryAlertResponseDto({
    this.success,
    this.expiringSoon = const [],
    this.expired      = const [],
  });

  factory ExpiryAlertResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    List<ExpiryAlertData> parseList(String key) =>
        (data[key] as List<dynamic>? ?? [])
            .map((e) => ExpiryAlertData.fromJson(e as Map<String, dynamic>))
            .toList();

    return ExpiryAlertResponseDto(
      success:      json['success'] as bool?,
      expiringSoon: parseList('expiring_soon'),
      expired:      parseList('expired'),
    );
  }

  /// Flat list — expired first so they appear at the top of the screen.
  List<ExpiryAlertData> get all => [...expired, ...expiringSoon];

  bool get isEmpty => expired.isEmpty && expiringSoon.isEmpty;
}


class ExpiryAlertData {
  final String? id;
  final String? product;
  final String? productName;
  final String? productSku;
  final String? shop;
  final String? shopName;
  final String? businessName;

  /// Stored as a string to mirror the rest of the inventory DTOs.
  final String? quantity;

  /// ISO date-only string: "2026-05-13"
  final String? expiryDate;

  final bool?   isExpired;
  final String? batchNumber;
  final String? createdAt;

  const ExpiryAlertData({
    this.id,
    this.product,
    this.productName,
    this.productSku,
    this.shop,
    this.shopName,
    this.businessName,
    this.quantity,
    this.expiryDate,
    this.isExpired,
    this.batchNumber,
    this.createdAt,
  });

  factory ExpiryAlertData.fromJson(Map<String, dynamic> json) {
    return ExpiryAlertData(
      id:           json['id']?.toString(),
      product:      json['product']?.toString(),
      productName:  json['product_name']?.toString(),
      productSku:   json['product_sku']?.toString(),
      shop:         json['shop']?.toString(),
      shopName:     json['shop_name']?.toString(),
      businessName: json['business_name']?.toString(),
      quantity:     _parseQtyString(json['quantity']),
      expiryDate:   json['expiry_date']?.toString(),
      isExpired:    _parseBool(json['is_expired']),
      batchNumber:  json['batch_number']?.toString(),
      createdAt:    json['created_at']?.toString(),
    );
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  double get qty {
    if (quantity == null || quantity!.trim().isEmpty) return 0;
    return double.tryParse(quantity!) ?? 0;
  }

  bool get isExpiredSafe  => isExpired ?? false;
  bool get isExpiringSoon => !isExpiredSafe;

  /// Parsed expiry date for display. Returns null if not set or unparseable.
  DateTime? get parsedExpiryDate {
    if (expiryDate == null || expiryDate!.isEmpty) return null;
    return DateTime.tryParse(expiryDate!);
  }

  /// Days until expiry, calculated locally from expiry_date.
  /// Negative = already expired by that many days.
  /// Null if expiry date is missing or unparseable.
  int? get calculatedExpiresInDays {
    final date = parsedExpiryDate;
    if (date == null) return null;
    final today = DateTime.now();
    final todayDate  = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(date.year, date.month, date.day);
    return expiryOnly.difference(todayDate).inDays;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _parseQtyString(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toString();
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true'  || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }
}
