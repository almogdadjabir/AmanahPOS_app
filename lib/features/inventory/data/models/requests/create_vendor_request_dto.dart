class CreateVendorRequestDto {
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  const CreateVendorRequestDto({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
    if (address != null && address!.trim().isNotEmpty) 'address': address!.trim(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}
