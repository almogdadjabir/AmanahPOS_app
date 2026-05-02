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

class User {
  String? id;
  String? phone;
  String? email;
  String? fullName;
  String? role;
  bool? isVerified;
  bool? hasPassword;
  String? createdAt;
  String? lastLoginAt;
  BankakAccountDto? bankakAccount;


  User(
      {this.id,
        this.phone,
        this.email,
        this.fullName,
        this.role,
        this.isVerified,
        this.hasPassword,
        this.createdAt,
        this.lastLoginAt,
        this.bankakAccount,});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phone = json['phone'];
    email = json['email'];
    fullName = json['full_name'];
    role = json['role'];
    isVerified = json['is_verified'];
    hasPassword = json['has_password'];
    createdAt = json['created_at'];
    lastLoginAt = json['last_login_at'];
    bankakAccount = json['bankak_account'] is Map<String, dynamic>
        ? BankakAccountDto.fromJson(
      json['bankak_account'] as Map<String, dynamic>,
    )
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['phone'] = phone;
    data['email'] = email;
    data['full_name'] = fullName;
    data['role'] = role;
    data['is_verified'] = isVerified;
    data['has_password'] = hasPassword;
    data['created_at'] = createdAt;
    data['last_login_at'] = lastLoginAt;
    return data;
  }
}

class BankakAccountDto {
  final String? id;
  final String? accountNumber;
  final bool? isDefault;
  final bool? isActive;
  final String? createdAt;

  const BankakAccountDto({
    this.id,
    this.accountNumber,
    this.isDefault,
    this.isActive,
    this.createdAt,
  });

  factory BankakAccountDto.fromJson(Map<String, dynamic> json) {
    return BankakAccountDto(
      id: json['id']?.toString(),
      accountNumber: json['account_number']?.toString(),
      isDefault: json['is_default'] as bool?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at']?.toString(),
    );
  }
}