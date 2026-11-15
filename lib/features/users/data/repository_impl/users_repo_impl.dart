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
    String? shopId,
  }) {
    return requestHandler.handlePostRequest(
      'api/v1/users/',
      (data) => UserData.fromJson(data as Map<String, dynamic>),
      data: {
        'phone': phone,
        'full_name': fullName,
        'role': role,
        if (shopId != null && shopId.isNotEmpty) 'default_shop_id': shopId,
      },
    );
  }

  @override
  Future<Either<String?, bool>> updateUser({
    required String userId,
    String? fullName,
    String? role,
    bool? isActive,
    String? shopId,
  }) {
    return requestHandler.handlePatchRequest(
      'api/v1/users/$userId/',
      (_) => true,
      data: {
        'full_name': ?fullName,
        'role': ?role,
        'is_active': ?isActive,
        'default_shop_id': ?shopId,
      },
    );
  }

  @override
  Future<Either<String?, bool>> deactivateUser(String userId) {
    return requestHandler.handleDeleteRequest(
      'api/v1/users/$userId/',
      (_) => true,
    );
  }
}
