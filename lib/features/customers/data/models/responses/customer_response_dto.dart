class CustomerResponseDto {
  final int? count;
  final int? totalPages;
  final int? currentPage;
  final String? next;
  final String? previous;
  final List<CustomerData> results;

  const CustomerResponseDto({
    this.count,
    this.totalPages,
    this.currentPage,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory CustomerResponseDto.fromJson(Map<String, dynamic> json) {
    return CustomerResponseDto(
      count: json['count'] as int?,
      totalPages: json['total_pages'] as int?,
      currentPage: json['current_page'] as int?,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => CustomerData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class CustomerData {
  final String? id;
  final String? tenant;
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final int? loyaltyPoints;
  final String? notes;
  final bool? isActive;
  final String? totalPurchases;
  final String? createdAt;
  final String? updatedAt;

  const CustomerData({
    this.id,
    this.tenant,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.loyaltyPoints,
    this.notes,
    this.isActive,
    this.totalPurchases,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      id: json['id']?.toString(),
      tenant: json['tenant']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      loyaltyPoints: json['loyalty_points'] as int?,
      notes: json['notes']?.toString(),
      isActive: json['is_active'] as bool?,
      totalPurchases: json['total_purchases']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  CustomerData copyWith({
    String? id,
    String? tenant,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? loyaltyPoints,
    String? notes,
    bool? isActive,
    String? totalPurchases,
    String? createdAt,
    String? updatedAt,
  }) {
    return CustomerData(
      id: id ?? this.id,
      tenant: tenant ?? this.tenant,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}