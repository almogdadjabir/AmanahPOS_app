class CustomerRequestDto {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;
  final int? loyaltyPoints;

  const CustomerRequestDto({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.notes,
    this.loyaltyPoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
    };
  }
}