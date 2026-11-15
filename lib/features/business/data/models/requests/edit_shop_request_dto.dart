class EditShopRequestDto {
  final String name;
  final String? address;
  final String? phone;
  final bool? isActive;

  const EditShopRequestDto({
    required this.name,
    this.address,
    this.phone,
    this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (isActive != null) 'is_active': isActive,
  };
}
