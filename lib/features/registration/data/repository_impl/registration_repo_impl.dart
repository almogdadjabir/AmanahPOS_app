import 'dart:async';

import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/registration/data/models/requests/init_registration_request_dto.dart';
import 'package:amana_pos/features/registration/data/models/responses/init_registration_response_dto.dart';
import 'package:amana_pos/features/registration/domain/repositories/registration_repository.dart';
import 'package:fpdart/fpdart.dart';

class RegistrationRepoImpl extends RegistrationRepository {
  final RequestHandler requestHandler;
  RegistrationRepoImpl(this.requestHandler);


  @override
  Future<Either<String?, InitRegistrationResponseDTO>> intRegistration(InitRegistrationRequestDTO request) {
    return requestHandler.handlePostRequest(
      'api/document/qr-code',
        data: request.toJson(),
        (data) => InitRegistrationResponseDTO.fromJson(data as Map<String, dynamic>),
    );
  }

}
