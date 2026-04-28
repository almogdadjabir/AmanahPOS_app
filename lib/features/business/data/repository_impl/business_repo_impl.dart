
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';

class BusinessRepoImpl extends BusinessRepository {
  final RequestHandler requestHandler;
  BusinessRepoImpl(this.requestHandler);


  // @override
  // Future<Either<String?, InitBusinessResponseDTO>> intBusiness(InitBusinessRequestDTO request) {
  //   return requestHandler.handlePostRequest(
  //     'api/document/qr-code',
  //       data: request.toJson(),
  //       (data) => InitBusinessResponseDTO.fromJson(data as Map<String, dynamic>),
  //   );
  // }

}
