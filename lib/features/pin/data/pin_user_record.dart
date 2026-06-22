class PinUserRecord {
  final String userId;
  final String businessId;
  final String tenantId;
  final String fullName;
  final String role;
  final String phone;
  final String pinSalt;
  final String pinHash;
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> profileJson;
  final String enrolledAt;
  final String lastUnlockAt;

  const PinUserRecord({
    required this.userId,
    required this.businessId,
    required this.tenantId,
    required this.fullName,
    required this.role,
    required this.phone,
    required this.pinSalt,
    required this.pinHash,
    required this.accessToken,
    required this.refreshToken,
    required this.profileJson,
    required this.enrolledAt,
    required this.lastUnlockAt,
  });

  PinUserRecord copyWith({String? lastUnlockAt}) => PinUserRecord(
        userId: userId,
        businessId: businessId,
        tenantId: tenantId,
        fullName: fullName,
        role: role,
        phone: phone,
        pinSalt: pinSalt,
        pinHash: pinHash,
        accessToken: accessToken,
        refreshToken: refreshToken,
        profileJson: profileJson,
        enrolledAt: enrolledAt,
        lastUnlockAt: lastUnlockAt ?? this.lastUnlockAt,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'businessId': businessId,
        'tenantId': tenantId,
        'fullName': fullName,
        'role': role,
        'phone': phone,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'profileJson': profileJson,
        'enrolledAt': enrolledAt,
        'lastUnlockAt': lastUnlockAt,
      };

  factory PinUserRecord.fromJson(Map<String, dynamic> json) => PinUserRecord(
        userId: json['userId'] as String? ?? '',
        businessId: json['businessId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        pinSalt: json['pinSalt'] as String? ?? '',
        pinHash: json['pinHash'] as String? ?? '',
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        profileJson:
            (json['profileJson'] as Map?)?.cast<String, dynamic>() ?? const {},
        enrolledAt: json['enrolledAt'] as String? ?? '',
        lastUnlockAt: json['lastUnlockAt'] as String? ?? '',
      );
}
