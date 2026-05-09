import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class UsersRepository {
  Future<Either<String?, UserResponseDto>> getUsers();

  // Returns the created UserData so the caller has the new user's ID.
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
  });

  Future<Either<String?, bool>> editUser({
    required String userId,
    required String fullName,
    required String role,
  });

  Future<Either<String?, bool>> deactivateUser(String userId);

  Future<Either<String?, bool>> assignShop({
    required String  userId,
    required String? shopId,
  });
}