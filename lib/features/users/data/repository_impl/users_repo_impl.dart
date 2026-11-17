import 'package:amana_pos/core/sync/catalog_result.dart';
import 'package:amana_pos/features/users/data/local/user_local_store.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:amana_pos/features/users/domain/user_conflict_service.dart';
import 'package:amana_pos/features/users/domain/user_service.dart';
import 'package:fpdart/fpdart.dart';

/// Local-first: reads the team from `synced_entities`, writes go through
/// [UserService] (row + outbox in one transaction). No REST call.
class UsersRepoImpl extends UsersRepository {
  UsersRepoImpl({
    required UserLocalStore store,
    required UserService Function() service,
    required UserConflictService Function() conflicts,
  }) : _store = store,
       _service = service,
       _conflicts = conflicts;

  final UserLocalStore _store;
  final UserService Function() _service;
  final UserConflictService Function() _conflicts;

  @override
  Future<Either<String?, UserResponseDto>> getUsers() async {
    try {
      return Right(
        UserResponseDto(success: true, data: await _store.readAll()),
      );
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String?, UserData>> addUser({
    required String phone,
    required String fullName,
    required String role,
    String? shopId,
  }) async {
    final r = await catalogResult(
      () => _service().create(
        phone: phone,
        fullName: fullName,
        role: role,
        shopId: shopId,
      ),
    );
    return r.fold(Left.new, (id) async {
      // The member is saved and queued: a failed re-read must not read as a
      // failed save (the owner would add the invite twice).
      UserData? u;
      try {
        u = await _store.readOne(id);
      } catch (_) {}
      return Right(
        u ?? UserData(id: id, phone: phone, fullName: fullName, role: role),
      );
    });
  }

  @override
  Future<Either<String?, bool>> updateUser({
    required String userId,
    String? fullName,
    String? role,
    bool? isActive,
    String? shopId,
  }) => catalogResult(() async {
    if (fullName != null || role != null || shopId != null) {
      await _service().update(
        userId,
        fullName: fullName,
        role: role,
        shopId: shopId,
      );
    }
    if (isActive != null) await _service().setActive(userId, isActive);
    return true;
  });

  @override
  Future<Either<String?, bool>> deactivateUser(String userId) =>
      catalogResult(() async {
        await _service().setActive(userId, false);
        return true;
      });

  @override
  Future<Either<String?, bool>> applyMineAgain(String mutationId) =>
      catalogResult(() async {
        await _conflicts().applyMineAgain(mutationId);
        return true;
      });

  @override
  Future<Either<String?, bool>> dismissConflict(String mutationId) =>
      catalogResult(() async {
        await _conflicts().dismiss(mutationId);
        return true;
      });
}
