class UserResponseDto {
  final bool? success;
  final List<UserData>? data;

  const UserResponseDto({this.success, this.data});

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((e) => UserData.fromJson(e))
          .toList(),
    );
  }
}

class UserData {
  final String? id;
  final String? phone;
  final String? fullName;
  final String? role;
  final bool? isVerified;
  final bool? isActive;
  final String? lastLoginAt;
  final String? createdAt;

  const UserData({
    this.id,
    this.phone,
    this.fullName,
    this.role,
    this.isVerified,
    this.isActive,
    this.lastLoginAt,
    this.createdAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      phone: json['phone'],
      fullName: json['full_name'],
      role: json['role'],
      isVerified: json['is_verified'],
      isActive: json['is_active'],
      lastLoginAt: json['last_login_at'],
      createdAt: json['created_at'],
    );
  }

  UserData copyWith({
    String? fullName,
    String? role,
    bool? isActive,
  }) {
    return UserData(
      id: id,
      phone: phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isVerified:  isVerified,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
    );
  }
}