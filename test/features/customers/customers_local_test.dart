import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/repository_impl/customer_repo_impl.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

void main() {
  late SaleFixture f;
  late CustomerRepoImpl repo;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    final svc = CustomerService(writer: f.writer, now: () => f.clock);
    repo = CustomerRepoImpl(writer: f.writer, service: () => svc);
    SyncScope.current = kScope;
  });
  tearDown(() async {
    SyncScope.current = null;
    f.notifier.dispose();
    await f.db.close();
  });

  Future<List<CustomerData>> list({
    String search = '',
    CustomerActiveFilter filter = CustomerActiveFilter.active,
    int page = 1,
    int size = 20,
  }) async => (await repo.getCustomers(
    page: page,
    pageSize: size,
    search: search,
    isActive: filter,
  )).getOrElse((_) => throw StateError('failed')).results;

  test('create offline appears immediately with a pending marker', () async {
    final r = await repo.createCustomer(
      request: const CustomerRequestDto(name: 'Ali', phone: '0912'),
    );
    expect(r.isRight(), isTrue);
    final c = (await list()).single;
    expect(c.name, 'Ali');
    expect(c.syncMark, CustomerSyncMark.pending);
  });

  test('search, active filter and paging work from local rows', () async {
    for (final n in ['Zed', 'Amal', 'Bashir']) {
      await repo.createCustomer(
        request: CustomerRequestDto(name: n, phone: '09$n'),
      );
    }
    final amal = (await list(search: 'amal')).single;
    await repo.setCustomerActive(customerId: amal.id!, isActive: false);
    expect((await list()).map((c) => c.name), ['Bashir', 'Zed']);
    expect(
      (await list(filter: CustomerActiveFilter.inactive)).single.name,
      'Amal',
    );
    expect(await list(filter: CustomerActiveFilter.all), hasLength(3));
    expect((await list(size: 1, page: 2)).single.name, 'Zed');
    expect(await list(search: '100%'), isEmpty);
  });

  test('empty name is refused locally', () async {
    final r = await repo.createCustomer(
      request: const CustomerRequestDto(name: ' '),
    );
    expect(r.isLeft(), isTrue);
  });
}
