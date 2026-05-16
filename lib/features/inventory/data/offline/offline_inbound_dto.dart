import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';

class OfflineInboundDto {
  final String clientInboundId;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String updatedAt;
  final CreateInboundRequestDto request;

  const OfflineInboundDto({
    required this.clientInboundId,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.request,
  });
}
