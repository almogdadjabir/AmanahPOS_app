import 'package:amana_pos/features/users/data/models/requests/add_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/requests/edit_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/add_user_response_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class UsersRepository {
  Future<Either<String?, UserResponseDto>> getUsers();
  Future<Either<String?, bool>> deactivateUser(String userId);
  Future<Either<String?, AddUserResponseDto>> addUser(AddUserRequestDto request);
  Future<Either<String?, bool>> editUser(String userId, EditUserRequestDto request);
}
