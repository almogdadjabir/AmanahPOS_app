class OtpExchangeResponse {
  String? accessToken;
  String? refreshToken;
  String? idToken;

  OtpExchangeResponse({this.accessToken, this.refreshToken, this.idToken});

  OtpExchangeResponse.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    idToken = json['idToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    data['idToken'] = idToken;
    return data;
  }
}