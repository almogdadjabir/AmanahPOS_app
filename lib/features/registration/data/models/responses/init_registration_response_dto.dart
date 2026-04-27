class InitRegistrationResponseDTO {
  bool? success;
  String? message;
  Data? data;

  InitRegistrationResponseDTO({this.success, this.message, this.data});

  InitRegistrationResponseDTO.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? userId;
  String? phone;

  Data({this.userId, this.phone});

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['phone'] = phone;
    return data;
  }
}