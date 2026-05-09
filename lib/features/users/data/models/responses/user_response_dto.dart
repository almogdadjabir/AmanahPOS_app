import 'package:equatable/equatable.dart';

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

class UserData extends Equatable {
  final String?  id;
  final String?  phone;
  final String?  email;
  final String?  fullName;
  final String?  role;
  final bool?    isActive;
  final bool?    isVerified;
  final String?  defaultShopId;    // MULTI-SHOP
  final String?  defaultShopName;  // MULTI-SHOP
  final String?  createdAt;
  final String?  lastLoginAt;

  const UserData({
    this.id,
    this.phone,
    this.email,
    this.fullName,
    this.role,
    this.isActive,
    this.isVerified,
    this.defaultShopId,
    this.defaultShopName,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id:              json['id']               as String?,
    phone:           json['phone']            as String?,
    email:           json['email']            as String?,
    fullName:        json['full_name']        as String?,
    role:            json['role']             as String?,
    isActive:        json['is_active']        as bool?,
    isVerified:      json['is_verified']      as bool?,
    defaultShopId:   json['default_shop_id']   as String?,  // M4
    defaultShopName: json['default_shop_name']  as String?, // M4
    createdAt:       json['created_at']        as String?,
    lastLoginAt:       json['lastLoginAt']        as String?,
  );

  @override
  List<Object?> get props => [
    id, phone, email, fullName, role, isActive, isVerified,
    defaultShopId, defaultShopName, createdAt, lastLoginAt,
  ];
}