import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:fpdart/fpdart.dart';

class UsersUseCase {
  final UsersRepository repository;
  UsersUseCase({required this.repository});

  Future<Either<String?, UserResponseDto>> getUsers() => repository.getUsers();

  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
    String? shopId,
  }) => repository.addUser(
    phone: phone,
    fullName: fullName,
    role: role,
    shopId: shopId,
  );

  Future<Either<String?, bool>> updateUser({
    required String userId,
    String? fullName,
    String? role,
    bool? isActive,
    String? shopId,
  }) => repository.updateUser(
    userId: userId,
    fullName: fullName,
    role: role,
    isActive: isActive,
    shopId: shopId,
  );

  Future<Either<String?, bool>> deactivateUser(String userId) =>
      repository.deactivateUser(userId);
}
