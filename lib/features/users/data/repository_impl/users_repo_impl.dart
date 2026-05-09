import 'package:amana_pos/core/api/request_handler.dart';
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
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
  }) {
    // POST returns the created user object — parse it as UserData
    return requestHandler.handlePostRequest(
      'api/v1/users/',
          (data) => UserData.fromJson(data as Map<String, dynamic>),
      data: {'phone': phone, 'full_name': fullName, 'role': role},
    );
  }

  @override
  Future<Either<String?, bool>> editUser({
    required String userId,
    required String fullName,
    required String role,
  }) {
    return requestHandler.handlePatchRequest(
      'api/v1/users/$userId/',
          (_) => true,
      data: {'full_name': fullName, 'role': role},
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
  Future<Either<String?, bool>> assignShop({
    required String  userId,
    required String? shopId,
  }) {
    return requestHandler.handlePatchRequest(
      'api/v1/users/$userId/',
          (_) => true,
      data: {'default_shop_id': shopId},
    );
  }
}
