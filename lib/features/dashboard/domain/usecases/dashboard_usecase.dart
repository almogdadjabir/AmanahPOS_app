import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:amana_pos/features/registration/data/models/requests/init_registration_request_dto.dart';
import 'package:amana_pos/features/registration/data/models/responses/init_registration_response_dto.dart';
import 'package:fpdart/fpdart.dart';

class DashboardUseCase {
  final DashboardRepository repository;

  DashboardUseCase({required this.repository});

}