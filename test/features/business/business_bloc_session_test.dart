import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _UseCase extends Mock implements BusinessUseCase {}

class _Cache extends Mock implements OfflineLocalCache {}

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<AppProgressCubit>()) {
      getIt.registerSingleton<AppProgressCubit>(AppProgressCubit());
    }
  });

  test('expired session (Left(null)) is a FAILURE, never "no businesses"', () async {
    final uc = _UseCase();
    final cache = _Cache();
    when(() => cache.getBusinesses()).thenAnswer((_) async => []);
    // The request handler returns Left(null) when the session has expired.
    when(
      () => uc.getBusinessList(),
    ).thenAnswer((_) async => const Left<String?, BusinessResponseDTO>(null));

    final bloc = BusinessBloc(useCase: uc, offlineLocalCache: cache);
    bloc.add(OnBusinessInitial());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.businessStatus, BusinessStatus.failure);
    verifyNever(() => cache.saveBusinessesToCache(any()));
    await bloc.close();
  });
}
