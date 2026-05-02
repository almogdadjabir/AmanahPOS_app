class SetPasswordRequestDto {
  final String password;
  final String passwordConfirm;

  const SetPasswordRequestDto({
    required this.password,
    required this.passwordConfirm,
  });

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'password_confirm': passwordConfirm,
    };
  }
}