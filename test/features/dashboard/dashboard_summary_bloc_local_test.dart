import 'package:amana_pos/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:amana_pos/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:amana_pos/features/dashboard/data/local/local_dashboard_queries.dart';
import 'package:amana_pos/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:amana_pos/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _NoRemote implements DashboardRemoteDataSource {
  int calls = 0;

  @override
  Future<DashboardSummaryDto> getDashboardSummary({
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int topSellersLimit = 5,
  }) async {
    calls++;
    throw StateError('REST dashboard must not be called with local data');
  }
}

SaleDraft _sale(String qty) => SaleDraft(
  shopId: kShop,
  paymentMethod: 'cash',
  lines: [
    SaleDraftLine.product(
      productId: kP1,
      productName: 'Tea',
      quantity: qty,
      unitPrice: '500',
    ),
  ],
);

void main() {
  late SaleFixture f;
  late _NoRemote remote;
  late DashboardSummaryBloc bloc;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    await f.seedShop(kShop);
    f.clock = DateTime.utc(2026, 11, 16, 8);
    remote = _NoRemote();
    bloc = DashboardSummaryBloc(
      getDashboardSummaryUseCase: GetDashboardSummaryUseCase(
        repository: DashboardRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: DashboardLocalDataSourceImpl(offlineDb: f.odb),
          localQueries: LocalDashboardQueries(
            db: f.odb,
            notifier: f.notifier,
            now: () => f.clock,
            tenantId: () => 'biz-1',
          ),
        ),
      ),
    );
  });

  tearDown(() async {
    await bloc.close();
    f.notifier.dispose();
    await f.db.close();
  });

  test('first emission is data (no loading), a later sale re-emits', () async {
    await f.service().createSale(_sale('1'));

    final states = <DashboardSummaryState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const OnDashboardSummaryStarted(shopId: kShop));

    await bloc.stream.firstWhere((s) => s.summary != null);
    expect(states, isNotEmpty);
    expect(states.first.status, DashboardSummaryStatus.success);
    expect(states.first.summary!.today.grossSalesAmount, 500);
    expect(
      states.any(
        (s) =>
            s.status == DashboardSummaryStatus.loading ||
            s.status == DashboardSummaryStatus.refreshing,
      ),
      isFalse,
    );

    await f.service().createSale(_sale('2'));
    final next = await bloc.stream
        .firstWhere((s) => s.summary!.today.salesCount == 2)
        .timeout(const Duration(seconds: 2));
    expect(next.summary!.today.grossSalesAmount, 1500);
    expect(next.status, DashboardSummaryStatus.success);

    // Refresh / restart never shows a spinner for local data either.
    bloc.add(const OnDashboardSummaryRefreshRequested());
    bloc.add(const OnDashboardSummaryShopChanged(shopId: kShop));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      states.where(
        (s) =>
            s.status == DashboardSummaryStatus.loading ||
            s.status == DashboardSummaryStatus.refreshing,
      ),
      isEmpty,
    );
    expect(bloc.state.summary!.today.salesCount, 2);
    expect(remote.calls, 0);
    await sub.cancel();
  });

  test('shop change re-subscribes to the new shop', () async {
    await f.service().createSale(_sale('1'));
    bloc.add(const OnDashboardSummaryStarted(shopId: kShop));
    await bloc.stream.firstWhere((s) => s.summary != null);

    bloc.add(const OnDashboardSummaryShopChanged(shopId: 'other-shop'));
    final s = await bloc.stream
        .firstWhere((s) => s.summary?.scope.shopId == 'other-shop')
        .timeout(const Duration(seconds: 2));
    expect(s.summary!.today.salesCount, 0);
    expect(s.shopId, 'other-shop');
  });

  test('reset cancels the local subscription', () async {
    bloc.add(const OnDashboardSummaryStarted(shopId: kShop));
    await bloc.stream.firstWhere((s) => s.summary != null);
    bloc.add(const OnDashboardSummaryReset());
    await bloc.stream.firstWhere((s) => s.summary == null);
    await f.service().createSale(_sale('1'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.summary, isNull);
  });
}
