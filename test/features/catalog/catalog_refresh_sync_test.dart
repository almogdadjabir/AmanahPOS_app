import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ProductUseCase extends Mock implements ProductUseCase {}

class _CategoryUseCase extends Mock implements CategoryUseCase {}

class _InventoryUseCase extends Mock implements InventoryUseCase {}

class _Cache extends Mock implements OfflineLocalCache {}

/// Ledger ruling (T7 C2): pull to refresh on the product, category and
/// vendor screens also asks the server for changes (SyncTriggers.syncNow),
/// fire and forget; a failing sync never surfaces.
void main() {
  late int calls;
  late bool fail;

  Future<void> syncNow() async {
    calls++;
    if (fail) throw StateError('offline');
  }

  setUp(() {
    calls = 0;
    fail = false;
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('products: OnProductsSyncRequested runs sync-now', () async {
    final bloc = ProductBloc(
      useCase: _ProductUseCase(),
      categoryUseCase: _CategoryUseCase(),
      offlineLocalCache: _Cache(),
      syncNow: syncNow,
    );
    bloc.add(const OnProductsSyncRequested());
    await settle();
    expect(calls, 1);
    fail = true;
    bloc.add(const OnProductsSyncRequested());
    await settle();
    expect(calls, 2);
    await bloc.close();
  });

  test('categories: OnCategoriesSyncRequested runs sync-now', () async {
    final bloc = CategoryBloc(
      useCase: _CategoryUseCase(),
      offlineLocalCache: _Cache(),
      syncNow: syncNow,
    );
    bloc.add(const OnCategoriesSyncRequested());
    await settle();
    expect(calls, 1);
    await bloc.close();
  });

  test('vendors: OnVendorsSyncRequested runs sync-now', () async {
    final bloc = VendorsBloc(
      useCase: _InventoryUseCase(),
      offlineLocalCache: _Cache(),
      syncNow: syncNow,
    );
    bloc.add(const OnVendorsSyncRequested());
    await settle();
    expect(calls, 1);
    await bloc.close();
  });

  test('no sync-now wired (kill switch): nothing happens', () async {
    final bloc = VendorsBloc(
      useCase: _InventoryUseCase(),
      offlineLocalCache: _Cache(),
    );
    bloc.add(const OnVendorsSyncRequested());
    await settle();
    expect(calls, 0);
    await bloc.close();
  });
}
