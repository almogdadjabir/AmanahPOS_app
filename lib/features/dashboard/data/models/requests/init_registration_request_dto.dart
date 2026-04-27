class InitRegistrationRequestDTO {
  String? phone;
  String? fullName;
  String? email;

  InitRegistrationRequestDTO({this.phone, this.fullName, this.email});

  InitRegistrationRequestDTO.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    fullName = json['full_name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phone'] = phone;
    data['full_name'] = fullName;
    data['email'] = email;
    return data;
  }
}