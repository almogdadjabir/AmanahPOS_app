import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';

class AddUserResponseDto {
  bool? success;
  String? message;
  UserData? data;

  AddUserResponseDto({this.success, this.message, this.data});

  AddUserResponseDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }
}