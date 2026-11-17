// Phase 3 Task 7: VendorsBloc reads SQLite only and writes through
// VendorService (InventoryRepoImpl -> InventoryUseCase).
import 'dart:convert';

import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Handler extends Mock implements RequestHandler {}

const kVendor = 'f0000000-0000-4000-8000-000000000001';

void main() {
  late SaleFixture f;
  late _Handler handler;
  late CatalogActor actor;
  late VendorService vendors;
  late VendorsBloc bloc;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    handler = _Handler();
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    vendors = VendorService(
      writer: f.writer,
      actor: () => actor,
      now: () => f.clock,
    );
    await f.db.insert('vendors', {
      'id': kVendor,
      'version': 3,
      'json': jsonEncode({'id': kVendor, 'name': 'Acme', 'is_active': true}),
    });
    bloc = VendorsBloc(
      useCase: InventoryUseCase(
        repository: InventoryRepoImpl(
          handler,
          stockService: () => StockService(
            writer: f.writer,
            actor: () => const StockActor(
              businessType: AppBusinessType.shop,
              role: AppUserRole.owner,
              shopId: null,
            ),
          ),
          vendorService: () => vendors,
        ),
      ),
      offlineLocalCache: OfflineLocalCache(f.odb),
      changes: f.notifier.changes,
    );
  });

  tearDown(() async {
    await bloc.close();
    f.notifier.dispose();
    await f.db.close();
  });

  Future<VendorsState> settle(bool Function(VendorsState) test) async {
    if (test(bloc.state)) return bloc.state;
    return bloc.stream.firstWhere(test).timeout(const Duration(seconds: 5));
  }

  /// The NEXT finished submit (call before adding the event).
  Future<VendorsState> submitted() => bloc.stream
      .firstWhere(
        (s) =>
            s.submitStatus == VendorsSubmitStatus.success ||
            s.submitStatus == VendorsSubmitStatus.failure,
      )
      .timeout(const Duration(seconds: 5));

  test('list shows an unsynced created vendor without any REST call', () async {
    final id = await vendors.create(const CreateVendorRequestDto(name: 'Bolt'));
    bloc.add(const OnVendorsStarted());
    final s = await settle(
      (s) => s.status == VendorsStatus.success && s.vendors.length == 2,
    );
    expect(s.syncMarks.isPendingSync(id), isTrue);
    expect(s.syncMarks.isPendingSync(kVendor), isFalse);
    verifyZeroInteractions(handler);
  });

  test('create, update and delete are local; the list follows', () async {
    bloc.add(const OnVendorsStarted());
    await settle((s) => s.status == VendorsStatus.success);

    var done = submitted();
    bloc.add(const OnVendorCreate(CreateVendorRequestDto(name: 'Bolt')));
    var s = await done;
    expect(s.submitStatus, VendorsSubmitStatus.success);
    expect(s.vendors.map((v) => v.name), containsAll(['Acme', 'Bolt']));

    done = submitted();
    bloc.add(
      const OnVendorUpdate(kVendor, UpdateVendorRequestDto(phone: '09')),
    );
    s = await done;
    expect(s.vendors.singleWhere((v) => v.id == kVendor).phone, '09');

    done = submitted();
    bloc.add(const OnVendorDelete(kVendor));
    s = await done;
    expect(s.submitStatus, VendorsSubmitStatus.success);
    expect(s.vendors.map((v) => v.id), isNot(contains(kVendor)));

    final ops = (await f.db.query(
      'outbox',
      orderBy: 'seq',
    )).map((r) => '${r['entity']}.${r['op']}').toList();
    expect(ops, ['vendor.create', 'vendor.update', 'vendor.delete']);
    verifyZeroInteractions(handler);
  });

  test('a write elsewhere re-reads the list', () async {
    bloc.add(const OnVendorsStarted());
    await settle((s) => s.status == VendorsStatus.success);
    await vendors.create(const CreateVendorRequestDto(name: 'Zed'));
    final s = await settle((s) => s.vendors.length == 2);
    expect(s.vendors.map((v) => v.name), contains('Zed'));
  });

  test('cashier: create is refused, nothing written', () async {
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.cashier,
    );
    final done = submitted();
    bloc.add(const OnVendorCreate(CreateVendorRequestDto(name: 'Bolt')));
    final s = await done;
    expect(s.submitStatus, VendorsSubmitStatus.failure);
    expect(s.submitError, contains('owners and managers'));
    expect(await f.db.query('outbox'), isEmpty);
  });
}
