import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inbound_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Handler extends Mock implements RequestHandler {}

const _vendor = '88888888-8888-4888-8888-888888888888';
const _remoteId = '99999999-9999-4999-8999-999999999999';

const _request = CreateInboundRequestDto(
  shopId: kShop,
  reference: 'INV-LOCAL',
  vendorId: _vendor,
  items: [CreateInboundItemRequestDto(productId: kP1, quantity: '3')],
);

const _remote = InboundTransactionData(
  id: _remoteId,
  reference: 'INV-REMOTE',
  shop: kShop,
  createdAt: '2026-11-15T08:00:00Z',
);

void main() {
  late SaleFixture f;
  late _Handler handler;
  late StockService service;
  late OfflineLocalCache cache;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    handler = _Handler();
    service = StockService(
      writer: f.writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
        shopId: null,
      ),
      now: () => f.clock,
    );
    cache = OfflineLocalCache(f.odb);
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Set<String>> historyIds() async => {
    for (final r in await f.db.query('inbound_transactions')) r['id'] as String,
  };

  group('saveInboundTransactions keeps unsynced local receipts', () {
    test('a local receipt with an open inbound.create row survives a REST '
        'refresh', () async {
      final local = await service.receiveInbound(_request);
      await cache.saveInboundTransactions(const [_remote]);
      expect(await historyIds(), {local.id, _remoteId});
    });

    test('once its outbox row is done, the REST list is the truth', () async {
      final local = await service.receiveInbound(_request);
      await f.db.update('outbox', {'status': 'done'});
      await cache.saveInboundTransactions(const [_remote]);
      expect(await historyIds(), {_remoteId});
      expect(local.id, isNot(_remoteId));
    });
  });

  test('InboundBloc: after a local submit the history is reloaded '
      'from the local table, no REST refresh; the receipt is listed', () async {
    final bloc = InboundBloc(
      useCase: InventoryUseCase(
        repository: InventoryRepoImpl(handler, stockService: () => service),
      ),
      offlineLocalCache: cache,
      isOnline: () async => true,
    );
    addTearDown(bloc.close);

    bloc.add(const OnInboundFormSubmit(_request));
    final s = await bloc.stream.firstWhere(
      (s) =>
          s.submitStatus == InboundSubmitStatus.success && s.history.isNotEmpty,
    );
    expect(s.history.single.reference, 'INV-LOCAL');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.history.map((e) => e.reference), ['INV-LOCAL']);
    verifyZeroInteractions(handler);
    expect(await historyIds(), hasLength(1));
  });
}
