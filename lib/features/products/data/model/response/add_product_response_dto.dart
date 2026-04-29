import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class AddProductResponseDto {
  bool? success;
  String? message;
  ProductData? data;

  AddProductResponseDto({this.success, this.message, this.data});

  AddProductResponseDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? ProductData.fromJson(json['data']) : null;
  }
}