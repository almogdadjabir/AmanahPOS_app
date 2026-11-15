class EditBusinessRequestDto {
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final bool? taxEnabled;
  final String? taxName;
  final double? taxRate;
  final bool? taxInclusive;

  const EditBusinessRequestDto({
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.taxEnabled,
    this.taxName,
    this.taxRate,
    this.taxInclusive,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (taxEnabled != null) 'tax_enabled': taxEnabled,
    if (taxName != null) 'tax_name': taxName,
    if (taxRate != null) 'tax_rate': taxRate,
    if (taxInclusive != null) 'tax_inclusive': taxInclusive,
  };
}
