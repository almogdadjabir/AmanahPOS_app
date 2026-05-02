import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';

class AddStockResponseDto {
  bool? success;
  String? message;
  StockData? data;

  AddStockResponseDto({this.success, this.message, this.data});

  AddStockResponseDto.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? StockData.fromJson(json['data']) : null;
  }
}