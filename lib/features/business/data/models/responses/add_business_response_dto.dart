import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';

class AddBusinessResponseDto {
  bool? success;
  String? message;
  BusinessData? data;

  AddBusinessResponseDto({this.success, this.message, this.data});

  AddBusinessResponseDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? BusinessData.fromJson(json['data']) : null;
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