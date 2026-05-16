class UpdateVendorRequestDto {
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool? isActive;

  const UpdateVendorRequestDto({
    this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null && name!.trim().isNotEmpty) map['name'] = name!.trim();
    if (phone != null) map['phone'] = phone!.trim();
    if (email != null) map['email'] = email!.trim();
    if (address != null) map['address'] = address!.trim();
    if (notes != null) map['notes'] = notes!.trim();
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
