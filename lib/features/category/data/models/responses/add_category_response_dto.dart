import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';

class AddCategoryResponseDto {
  bool? success;
  String? message;
  CategoryData? data;

  AddCategoryResponseDto({this.success, this.message, this.data});

  AddCategoryResponseDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? CategoryData.fromJson(json['data']) : null;
  }
}