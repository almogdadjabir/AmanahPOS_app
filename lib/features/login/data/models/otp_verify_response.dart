import 'package:equatable/equatable.dart';

class OtpVerifyResponse {
  bool? success;
  String? message;
  LoginData? loginData;

  OtpVerifyResponse({this.success, this.message, this.loginData});

  OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    loginData = json['data'] != null ? LoginData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (loginData != null) {
      data['data'] = loginData!.toJson();
    }
    return data;
  }
}

class LoginData {
  String? access;
  String? refresh;
  User? user;

  LoginData({this.access, this.refresh, this.user});

  LoginData.fromJson(Map<String, dynamic> json) {
    access = json['access'];
    refresh = json['refresh'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access'] = access;
    data['refresh'] = refresh;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User extends Equatable {
  final String? id;
  final String? phone;
  final String? email;
  final String? fullName;
  final String? role;
  final bool? isStaff;
  final bool? isVerified;
  final bool? hasPassword;
  final String? businessId;
  final String? defaultShopId;
  final String? defaultShopName;
  final BankakAccount? bankakAccount;
  final String? createdAt;
  final String? lastLoginAt;
  final Map<String, bool> enabledFeatures;

  const User({
    this.id,
    this.phone,
    this.email,
    this.fullName,
    this.role,
    this.isStaff,
    this.isVerified,
    this.hasPassword,
    this.businessId,
    this.defaultShopId,
    this.defaultShopName,
    this.bankakAccount,
    this.createdAt,
    this.lastLoginAt,
    this.enabledFeatures = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    fullName: json['full_name'] as String?,
    role: json['role'] as String?,
    isStaff: json['is_staff'] as bool?,
    isVerified: json['is_verified'] as bool?,
    hasPassword: json['has_password'] as bool?,
    businessId: json['business_id'] as String?,
    defaultShopId: json['default_shop_id'] as String?,
    defaultShopName: json['default_shop_name'] as String?,
    bankakAccount: json['bankak_account'] != null
        ? BankakAccount.fromJson(
        json['bankak_account'] as Map<String, dynamic>)
        : null,
    createdAt: json['created_at'] as String?,
    lastLoginAt: json['last_login_at'] as String?,
    enabledFeatures: _parseEnabledFeatures(json['enabled_features']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'full_name': fullName,
    'role': role,
    'is_staff': isStaff,
    'is_verified': isVerified,
    'has_password': hasPassword,
    'business_id': businessId,
    'default_shop_id': defaultShopId,
    'default_shop_name': defaultShopName,
    'bankak_account': bankakAccount?.toJson(),
    'created_at': createdAt,
    'last_login_at': lastLoginAt,
    'enabled_features': enabledFeatures,
  };

  static Map<String, bool> _parseEnabledFeatures(dynamic value) {
    if (value is! Map) return const {};

    return value.map((key, val) {
      return MapEntry(key.toString(), val == true);
    });
  }

  @override
  List<Object?> get props => [
    id, phone, email, fullName, role, isStaff, isVerified,
    hasPassword, businessId, defaultShopId, defaultShopName,
    bankakAccount, createdAt, lastLoginAt, enabledFeatures,
  ];
}

class BankakAccount extends Equatable {
  final String? id;
  final String? accountNumber;

  const BankakAccount({this.id, this.accountNumber});

  factory BankakAccount.fromJson(Map<String, dynamic> json) => BankakAccount(
    id: json['id'] as String?,
    accountNumber: json['account_number'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_number': accountNumber,
  };

  @override
  List<Object?> get props => [id, accountNumber];
}