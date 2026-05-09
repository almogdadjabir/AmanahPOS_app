import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:fpdart/fpdart.dart';

class UsersUseCase {
  final UsersRepository repository;
  UsersUseCase({required this.repository});

  Future<Either<String?, UserResponseDto>> getUsers() =>
      repository.getUsers();

  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
  }) => repository.addUser(phone: phone, fullName: fullName, role: role);

  Future<Either<String?, bool>> editUser({
    required String userId,
    required String fullName,
    required String role,
  }) => repository.editUser(userId: userId, fullName: fullName, role: role);

  Future<Either<String?, bool>> deactivateUser(String userId) =>
      repository.deactivateUser(userId);

  Future<Either<String?, bool>> assignShop({
    required String  userId,
    required String? shopId,
  }) => repository.assignShop(userId: userId, shopId: shopId);
}
