import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';

class UserProfileDto {
  bool? success;
  User? user;

  UserProfileDto({this.success, this.user});

  UserProfileDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    user = json['data'] != null ? new User.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (user != null) {
      data['data'] = user!.toJson();
    }
    return data;
  }
}