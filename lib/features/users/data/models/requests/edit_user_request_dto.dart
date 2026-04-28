class EditUserRequestDto {
  final String fullName;
  final String? phone;
  final String? role;

  const EditUserRequestDto({
    required this.fullName,
    this.phone,
    this.role,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    if (role != null) 'address': role,
    if (phone != null) 'phone': phone,
  };
}