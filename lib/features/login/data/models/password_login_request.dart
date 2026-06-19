class PasswordLoginRequest {
  String? phone;
  String? password;

  PasswordLoginRequest({this.phone, this.password});

  PasswordLoginRequest.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phone'] = phone;
    data['password'] = password;
    return data;
  }
}
