import 'dart:async';

import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fpdart/fpdart.dart';

import '../models/requests/init_registration_request_dto.dart';
import '../models/responses/init_registration_response_dto.dart';

class DashboardRepoImpl extends DashboardRepository {
  final RequestHandler requestHandler;
  DashboardRepoImpl(this.requestHandler);


}
