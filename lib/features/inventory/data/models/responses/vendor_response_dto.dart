class VendorData {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool isActive;

  const VendorData({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.isActive,
  });

  factory VendorData.fromJson(Map<String, dynamic> json) {
    // Handles both wrapped {"success":true,"data":{...}} and flat responses
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return VendorData(
      id: d['id']?.toString() ?? '',
      name: d['name']?.toString() ?? '',
      phone: d['phone']?.toString(),
      email: d['email']?.toString(),
      address: d['address']?.toString(),
      notes: d['notes']?.toString(),
      isActive: d['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'notes': notes,
    'is_active': isActive,
  };

  VendorData copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) {
    return VendorData(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}

class VendorListResponseDto {
  final int count;
  final int totalPages;
  final List<VendorData> results;

  const VendorListResponseDto({
    required this.count,
    required this.totalPages,
    required this.results,
  });

  factory VendorListResponseDto.fromJson(Map<String, dynamic> json) {
    return VendorListResponseDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      results: (json['results'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(VendorData.fromJson)
              .toList() ??
          const [],
    );
  }
}
