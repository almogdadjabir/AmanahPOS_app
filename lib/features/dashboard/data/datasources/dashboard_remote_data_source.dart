import 'package:amana_pos/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:dio/dio.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryDto> getDashboardSummary({
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int topSellersLimit = 5,
  });
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  const DashboardRemoteDataSourceImpl({
    required this.dio,
  });

  static const String _endpoint = '/api/v1/sales/dashboard-summary/';

  @override
  Future<DashboardSummaryDto> getDashboardSummary({
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int topSellersLimit = 5,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      _endpoint,
      queryParameters: {
        if (businessId != null && businessId.isNotEmpty)
          'business_id': businessId,
        if (shopId != null && shopId.isNotEmpty) 'shop_id': shopId,
        if (date != null) 'date': _formatDate(date),
        if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
        'top_sellers_limit': topSellersLimit.clamp(1, 20),
      },
    );

    final data = response.data ?? <String, dynamic>{};

    if (data['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: data['message']?.toString() ?? 'Failed to load dashboard',
      );
    }

    return DashboardSummaryDto.fromJson(data);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}