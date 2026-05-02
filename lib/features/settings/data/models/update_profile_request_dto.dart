class UpdateProfileRequestDto {
  final String fullName;
  final String? email;
  final String? bankakAccountNumber;

  const UpdateProfileRequestDto({
    required this.fullName,
    this.email,
    this.bankakAccountNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      if (email != null) 'email': email,
      if (bankakAccountNumber != null)
        'bankak_account_number': bankakAccountNumber,
    };
  }
}