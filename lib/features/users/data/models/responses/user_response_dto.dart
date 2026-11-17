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

/// Row marker of a team member (derived from the outbox).
enum UserSyncMark { synced, pending, failed }

/// A rejected outbox row of a team member the owner has to act on.
class UserConflict extends Equatable {
  const UserConflict({
    required this.mutationId,
    required this.op,
    required this.code,
    this.message,
    this.payload = const {},
  });

  final String mutationId;
  final String op;
  final String code;
  final String? message;
  final Map<String, dynamic> payload;

  /// A role/shop change refused because the member changed meanwhile.
  bool get isVersionConflict => code == 'conflict_version';

  @override
  List<Object?> get props => [mutationId, op, code, message, payload];
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

  /// Server row version; null while the create is unsent.
  final int? version;
  final UserSyncMark syncMark;
  final UserConflict? conflict;

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
    this.version,
    this.syncMark = UserSyncMark.synced,
    this.conflict,
  });

  /// Created here and not yet confirmed by the server ("Invite pending").
  bool get isLocalOnly => version == null;

  /// Reads the feed shape (`default_shop`, `status`) and the legacy REST
  /// shape (`default_shop_id`, `is_verified`).
  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json['id'] as String?,
    phone: json['phone'] as String?,
    fullName: json['full_name'] as String?,
    role: json['role'] as String?,
    isActive: json['is_active'] as bool?,
    isVerified: json['is_verified'] is bool
        ? json['is_verified'] as bool
        : (json['status'] is String ? json['status'] != 'invited' : null),
    defaultShopId: (json['default_shop_id'] ?? json['default_shop']) as String?,
    createdAt: json['created_at'] as String?,
    lastLoginAt: json['last_login_at'] as String?,
    version: json['version'] is int ? json['version'] as int : null,
  );

  UserData withMarks(UserSyncMark mark, UserConflict? conflict) => UserData(
    id: id,
    phone: phone,
    fullName: fullName,
    role: role,
    isActive: isActive,
    isVerified: isVerified,
    defaultShopId: defaultShopId,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
    version: version,
    syncMark: mark,
    conflict: conflict,
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
    version: version,
    syncMark: syncMark,
    conflict: conflict,
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
    version,
    syncMark,
    conflict,
  ];
}
