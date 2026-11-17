import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class UsersRepository {
  Future<Either<String?, UserResponseDto>> getUsers();

  /// Returns the created user. [shopId] is sent in the create body.
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
    String? shopId,
  });

  /// PATCH: only the non-null fields are sent.
  Future<Either<String?, bool>> updateUser({
    required String userId,
    String? fullName,
    String? role,
    bool? isActive,
    String? shopId,
  });

  /// DELETE = deactivate.
  Future<Either<String?, bool>> deactivateUser(String userId);

  /// Re-sends a refused role/shop change against the member's current
  /// server version (the server may refuse it again).
  Future<Either<String?, bool>> applyMineAgain(String mutationId);

  /// Drops a refused team change; the member shows the server state.
  Future<Either<String?, bool>> dismissConflict(String mutationId);
}
