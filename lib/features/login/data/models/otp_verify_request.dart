class OtpVerifyRequest {
  String? phone;
  String? otp;
  String? fcmToken;
  String? platform;
  String? deviceId;
  String? appVersion;

  OtpVerifyRequest(
      {this.phone,
        this.otp,
        this.fcmToken,
        this.platform,
        this.deviceId,
        this.appVersion});

  OtpVerifyRequest.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    otp = json['otp'];
    fcmToken = json['fcm_token'];
    platform = json['platform'];
    deviceId = json['device_id'];
    appVersion = json['app_version'];
  }
  Map<String, dynamic> toJson() => {
    'phone': phone,
    'otp': otp,
    if (fcmToken != null) 'fcm_token': fcmToken,
    if (platform != null) 'platform': platform,
    if (deviceId != null) 'device_id': deviceId,
    if (appVersion != null) 'app_version': appVersion,
  };

}