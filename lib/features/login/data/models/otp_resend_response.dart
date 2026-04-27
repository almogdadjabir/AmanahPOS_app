class OtpResendResponse {
  String? maskedPhone;
  String? otpIdentifierId;

  OtpResendResponse({this.maskedPhone, this.otpIdentifierId});

  OtpResendResponse.fromJson(Map<String, dynamic> json) {
    maskedPhone = json['maskedPhone'];
    otpIdentifierId = json['otpIdentifierId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['maskedPhone'] = maskedPhone;
    data['otpIdentifierId'] = otpIdentifierId;
    return data;
  }
}