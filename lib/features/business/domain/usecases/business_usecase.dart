import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';

class BusinessUseCase {
  final BusinessRepository repository;

  BusinessUseCase({required this.repository});

  // Future<Either<String?, InitBusinessResponseDTO>> intBusiness(InitBusinessRequestDTO request) => repository.intBusiness(request);

}