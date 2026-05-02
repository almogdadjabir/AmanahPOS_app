import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';

class AddCustomerResponseDto {
  bool? success;
  String? message;
  CustomerData? data;

  AddCustomerResponseDto({this.success, this.message, this.data});

  AddCustomerResponseDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? CustomerData.fromJson(json['data']) : null;
  }
}