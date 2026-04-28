class EditBusinessRequestDto {
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  const EditBusinessRequestDto({
    required this.name,
    this.address,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
  };
}