class CustomerRequestDto {
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool? isActive;

  const CustomerRequestDto({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
    };
  }
}
