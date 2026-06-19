/// Supported countries for phone-based login.
///
/// Single source of truth for the flag, dial code, and hint shown in
/// [PhoneNumberField]. Both Sudan and UAE mobile numbers are 9 digits
/// (10 with a leading 0), so validation is shared via `phoneMaxLength`.
enum LoginCountry {
  sudan(flag: '🇸🇩', dialCode: '+249', hint: '912345678', label: 'Sudan'),
  uae(flag: '🇦🇪', dialCode: '+971', hint: '544097335', label: 'UAE');

  const LoginCountry({
    required this.flag,
    required this.dialCode,
    required this.hint,
    required this.label,
  });

  final String flag;
  final String dialCode;
  final String hint;
  final String label;
}
