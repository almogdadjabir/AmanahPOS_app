class AddShopRequestDto {
  final String name;
  final String? address;
  final String? phone;

  const AddShopRequestDto({
    required this.name,
    this.address,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
  };
}