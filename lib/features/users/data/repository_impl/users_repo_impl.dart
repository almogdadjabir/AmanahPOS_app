
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/users/data/models/requests/add_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/requests/edit_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/add_user_response_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:fpdart/fpdart.dart';

class UsersRepoImpl extends UsersRepository {
  final RequestHandler requestHandler;
  UsersRepoImpl(this.requestHandler);

  @override
  Future<Either<String?, UserResponseDto>> getUsers() {
    return requestHandler.handleGetRequest(
      'api/v1/users/',
          (data) => UserResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, AddUserResponseDto>> addUser(AddUserRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/users/',
          (data) => AddUserResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, bool>> deactivateUser(String userId) {
    return requestHandler.handleDeleteRequest(
      'api/v1/users/$userId/',
          (_) => true,
    );
  }

  @override
  Future<Either<String?, bool>> editUser(String userId, EditUserRequestDto request) {
    return requestHandler.handlePatchRequest(
      'api/v1/users/$userId/',
          (_) => true,
      data: request.toJson(),
    );
  }
}
