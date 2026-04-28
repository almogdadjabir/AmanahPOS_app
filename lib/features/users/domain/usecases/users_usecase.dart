import 'package:amana_pos/features/users/data/models/requests/add_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/requests/edit_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/add_user_response_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:fpdart/fpdart.dart';


class UsersUseCase {
  final UsersRepository repository;

  UsersUseCase({required this.repository});

  Future<Either<String?, UserResponseDto>> getUsers() => repository.getUsers();
  Future<Either<String?, bool>> deactivateUser(String userId) => repository.deactivateUser(userId);
  Future<Either<String?, AddUserResponseDto>> addUser(AddUserRequestDto request) => repository.addUser(request);
  Future<Either<String?, bool>> editUser(String userId, EditUserRequestDto request) => repository.editUser(userId, request);
}