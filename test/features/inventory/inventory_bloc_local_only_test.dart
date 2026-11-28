import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Handler extends Mock implements RequestHandler {}

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<AppProgressCubit>()) {
      getIt.registerSingleton<AppProgressCubit>(AppProgressCubit());
    }
  });

  test('stock screen reads the LOCAL list once: no API replace, no paging, '
      'numbers do not change while loading', () async {
    final f = await SaleFixture.on(await openTestDb());
    final handler = _Handler();
    final repo = InventoryRepoImpl(
      handler,
      stockService: () => StockService(
        writer: f.writer,
        actor: () => const StockActor(
          businessType: AppBusinessType.shop,
          role: AppUserRole.manager,
          shopId: kShop,
        ),
        now: () => f.clock,
      ),
      expiryAddSynced: () async => false,
    );
    final bloc = InventoryBloc(
      useCase: InventoryUseCase(repository: repo),
      offlineLocalCache: OfflineLocalCache(f.odb),
      isOnline: () async => true,
      expiryAddSynced: () async => false,
    );

    final states = <InventoryState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const OnInventoryInitial());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await sub.cancel();

    verifyNever(() => handler.handleGetRequest<dynamic>(any(), any()));
    final lists = states.map((s) => s.stockList.length).toSet();
    expect(lists.length, 1, reason: 'list size changed while loading: $lists');
    expect(states.last.hasMorePages, isFalse);
    expect(states.last.stockList, isNotEmpty);
    await bloc.close();
    f.notifier.dispose();
    await f.db.close();
  });
}
