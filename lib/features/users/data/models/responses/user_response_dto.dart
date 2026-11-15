import 'package:equatable/equatable.dart';

class UserResponseDto {
  final bool? success;
  final List<UserData>? data;

  const UserResponseDto({this.success, this.data});

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((e) => UserData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A staff member as returned by `api/v1/users/` (owner only).
class UserData extends Equatable {
  final String? id;
  final String? phone;
  final String? fullName;
  final String? role;
  final bool? isActive;
  final bool? isVerified;
  final String? defaultShopId;
  final String? createdAt;
  final String? lastLoginAt;

  const UserData({
    this.id,
    this.phone,
    this.fullName,
    this.role,
    this.isActive,
    this.isVerified,
    this.defaultShopId,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json['id'] as String?,
    phone: json['phone'] as String?,
    fullName: json['full_name'] as String?,
    role: json['role'] as String?,
    isActive: json['is_active'] as bool?,
    isVerified: json['is_verified'] as bool?,
    defaultShopId: json['default_shop_id'] as String?,
    createdAt: json['created_at'] as String?,
    lastLoginAt: json['last_login_at'] as String?,
  );

  /// Copy with the editable fields replaced (shop can only be set, not cleared).
  UserData patched({
    String? fullName,
    String? role,
    bool? isActive,
    String? shopId,
  }) => UserData(
    id: id,
    phone: phone,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    isActive: isActive ?? this.isActive,
    isVerified: isVerified,
    defaultShopId: shopId ?? defaultShopId,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
  );

  @override
  List<Object?> get props => [
    id,
    phone,
    fullName,
    role,
    isActive,
    isVerified,
    defaultShopId,
    createdAt,
    lastLoginAt,
  ];
}
