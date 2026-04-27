import 'package:amana_pos/features/registration/data/models/requests/init_registration_request_dto.dart';
import 'package:amana_pos/features/registration/data/models/responses/init_registration_response_dto.dart';
import 'package:amana_pos/features/registration/domain/repositories/registration_repository.dart';
import 'package:fpdart/fpdart.dart';

class RegistrationUseCase {
  final RegistrationRepository repository;

  RegistrationUseCase({required this.repository});

  Future<Either<String?, InitRegistrationResponseDTO>> intRegistration(InitRegistrationRequestDTO request) => repository.intRegistration(request);

}