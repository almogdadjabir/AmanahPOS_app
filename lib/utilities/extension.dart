extension StringX on String? {
  String get initials {
    if (this == null || this!.trim().isEmpty) return '?';
    final parts = this!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}