class OtpExchangeRequest {
  String? otpIdentifierId;
  String? preferredLanguage;
  String? timezone;
  DeviceData? deviceData;

  OtpExchangeRequest(
      {this.otpIdentifierId,
        this.preferredLanguage,
        this.timezone,
        this.deviceData});

  OtpExchangeRequest.fromJson(Map<String, dynamic> json) {
    otpIdentifierId = json['otpIdentifierId'];
    preferredLanguage = json['preferredLanguage'];
    timezone = json['timezone'];
    deviceData = json['deviceData'] != null
        ? DeviceData.fromJson(json['deviceData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['otpIdentifierId'] = otpIdentifierId;
    data['preferredLanguage'] = preferredLanguage;
    data['timezone'] = timezone;
    if (deviceData != null) {
      data['deviceData'] = deviceData!.toJson();
    }
    return data;
  }
}

class DeviceData {
  String? manufacturer;
  String? model;
  String? platform;
  String? osVersion;
  String? fcmToken;

  DeviceData(
      {this.manufacturer,
        this.model,
        this.platform,
        this.osVersion,
        this.fcmToken});

  DeviceData.fromJson(Map<String, dynamic> json) {
    manufacturer = json['manufacturer'];
    model = json['model'];
    platform = json['platform'];
    osVersion = json['osVersion'];
    fcmToken = json['fcmToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['manufacturer'] = manufacturer;
    data['model'] = model;
    data['platform'] = platform;
    data['osVersion'] = osVersion;
    data['fcmToken'] = fcmToken;
    return data;
  }
}