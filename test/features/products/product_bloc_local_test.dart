// Phase 3 Task 7: ProductBloc reads SQLite only and writes through
// ProductService (repo -> use case). No REST client exists in this setup:
// the repos take no RequestHandler, so any REST call would not compile.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/data/repository_impl/category_repo_impl.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/repository_impl/product_repo_impl.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const kCat = 'c0000000-0000-4000-8000-000000000001';

/// Counts full product-list reads (review M10).
class _CountingCache extends OfflineLocalCache {
  _CountingCache(super.db);
  int productReads = 0;

  @override
  Future<List<ProductData>> getProducts({
    String? categoryId,
    String? search,
    bool? isActive,
  }) {
    productReads++;
    return super.getProducts(
      categoryId: categoryId,
      search: search,
      isActive: isActive,
    );
  }
}
const kSynced = 'd0000000-0000-4000-8000-000000000001';

void main() {
  late SaleFixture f;
  late CatalogActor actor;
  late Directory base;
  late PendingUploadStore uploads;
  late CategoryService categories;
  late ProductService products;
  late ProductBloc bloc;

  ProductBloc build() => ProductBloc(
    useCase: ProductUseCase(
      repository: ProductRepoImpl(service: () => products),
    ),
    categoryUseCase: CategoryUseCase(
      repository: CategoryRepoImpl(service: () => categories),
    ),
    offlineLocalCache: OfflineLocalCache(f.odb),
    changes: f.notifier.changes,
  );

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    base = await Directory.systemTemp.createTemp('product_bloc_local');
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    uploads = PendingUploadStore(baseDir: () async => base.path);
    categories = CategoryService(
      writer: f.writer,
      actor: () => actor,
      uploads: uploads,
      now: () => f.clock,
    );
    products = ProductService(
      writer: f.writer,
      actor: () => actor,
      uploads: uploads,
      categories: categories,
      now: () => f.clock,
    );
    // The fixture's bare seed products have no is_active/category: drop them
    // so the list holds only what each test writes.
    await f.db.delete('products');
    await f.db.insert('categories', {
      'id': kCat,
      'tenant_id': 't1',
      'name': 'Drinks',
      'version': 2,
      'json': jsonEncode({
        'id': kCat,
        'name': 'Drinks',
        'is_active': true,
        'product_count': 1,
      }),
    });
    await f.db.insert('products', {
      'id': kSynced,
      'category_id': kCat,
      'name': 'Tea',
      'price': '5.00',
      'stock_level': 0.0,
      'version': 4,
      'json': jsonEncode({
        'id': kSynced,
        'category': kCat,
        'name': 'Tea',
        'price': '5.00',
        'unit': 'piece',
        'is_active': true,
        'track_inventory': true,
        'stock_level': 0.0,
      }),
    });
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    f.notifier.dispose();
    await f.db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  });

  AddProductRequestDto dto({
    String name = 'Cola',
    String category = kCat,
    PickedAppImage? image,
  }) => AddProductRequestDto(
    name: name,
    price: '12.50',
    category: category,
    unit: 'piece',
    trackInventory: true,
    imageUpload: image,
  );

  Future<ProductState> settle(bool Function(ProductState) test) async {
    if (test(bloc.state)) return bloc.state;
    return bloc.stream
        .firstWhere(test)
        .timeout(const Duration(seconds: 5));
  }

  /// The NEXT finished submit (call before adding the event).
  Future<ProductState> submitted() => bloc.stream
      .firstWhere(
        (s) =>
            s.submitStatus == ProductSubmitStatus.success ||
            s.submitStatus == ProductSubmitStatus.failure,
      )
      .timeout(const Duration(seconds: 5));

  Future<List<Map<String, Object?>>> outbox() =>
      f.db.query('outbox', orderBy: 'seq');

  test('list shows an unsynced created product without any REST call', () async {
    final id = await products.create(dto());
    bloc.add(const OnProductInitial());
    final s = await settle(
      (s) => s.productStatus == ProductStatus.success && s.products.length == 2,
    );
    expect(s.products.map((p) => p.name), ['Cola', 'Tea']);
    expect(s.isFromCache, isFalse);
    expect(s.hasMorePages, isFalse);
    expect(s.categories.single.id, kCat);
    expect(s.syncMarks.isPendingSync(id), isTrue);
    expect(s.syncMarks.isPendingSync(kSynced), isFalse);
    expect(s.syncMarks.syncFailed(id), isFalse);
  });

  test('a write elsewhere (pull or another screen) re-reads the list via the '
      'change notifier', () async {
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    expect(bloc.state.products, hasLength(1));
    await products.create(dto(name: 'Juice'));
    final s = await settle((s) => s.products.length == 2);
    expect(s.products.map((p) => p.name), contains('Juice'));
  });

  test('add product with image returns immediately offline and the row '
      'appears', () async {
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final file = File(p.join(base.path, 'picker', 'a.jpg'));
    await file.create(recursive: true);
    await file.writeAsBytes(List.generate(64, (i) => i));
    final image = PickedAppImage(file: file, path: file.path, name: 'a.jpg');

    final done = submitted();
    bloc.add(OnAddProduct(dto: dto(image: image)));
    final s = await done;
    expect(s.submitStatus, ProductSubmitStatus.success);
    final cola = s.products.singleWhere((p) => p.name == 'Cola');
    expect(s.syncMarks.isPendingSync(cola.id!), isTrue);
    final upload = (await f.db.query('pending_uploads')).single;
    expect(upload['entity'], 'product');
    expect(upload['entity_id'], cola.id);
    final create = (await outbox()).single;
    expect(create['op'], 'create');
    expect(
      (jsonDecode(create['payload_json'] as String) as Map)['image_pending'],
      true,
    );
  });

  test('add with the auto "General" category and opening stock is ONE write: '
      'category.create, product.create, stock.add', () async {
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final done = submitted();
    bloc.add(
      OnAddProductWithAutoCategory(
        dto: dto(category: ''),
        openingStock: '3',
        openingShopId: kShop,
      ),
    );
    final s = await done;
    expect(s.submitStatus, ProductSubmitStatus.success);
    final rows = await outbox();
    expect(rows.map((r) => '${r['entity']}.${r['op']}'), [
      'category.create',
      'product.create',
      'stock.add',
    ]);
    expect(s.categories.map((c) => c.name), contains('General'));
    final cola = s.products.singleWhere((p) => p.name == 'Cola');
    expect(cola.stockLevel, 3.0, reason: 'read from local stock, not patched');
  });

  test('a refused add (duplicate barcode) fails the submit and writes '
      'nothing', () async {
    await products.create(
      const AddProductRequestDto(
        name: 'X',
        price: '1',
        category: kCat,
        unit: 'piece',
        trackInventory: true,
        barcode: 'B1',
      ),
    );
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final done = submitted();
    bloc.add(
      const OnAddProduct(
        dto: AddProductRequestDto(
          name: 'Y',
          price: '1',
          category: kCat,
          unit: 'piece',
          trackInventory: true,
          barcode: 'B1',
        ),
      ),
    );
    final s = await done;
    expect(s.submitStatus, ProductSubmitStatus.failure);
    expect(s.submitError, isNotEmpty);
    expect(await outbox(), hasLength(1));
    expect(s.products.map((p) => p.name), isNot(contains('Y')));
  });

  test('edit is written locally and the list shows it at once', () async {
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final done = submitted();
    bloc.add(
      const OnUpdateProduct(
        productId: kSynced,
        dto: UpdateProductRequestDto(
          name: 'Green tea',
          price: '5.00',
          category: kCat,
          unit: 'piece',
          trackInventory: true,
        ),
      ),
    );
    final s = await done;
    expect(s.submitStatus, ProductSubmitStatus.success);
    expect(s.products.single.name, 'Green tea');
    expect(s.syncMarks.isPendingSync(kSynced), isTrue);
    final row = (await outbox()).single;
    expect([row['op'], row['base_version']], ['update', 4]);
  });

  test('delete hides the row at once', () async {
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final done = submitted();
    bloc.add(const OnDeleteProduct(productId: kSynced));
    final s = await done;
    expect(s.submitStatus, ProductSubmitStatus.success);
    expect(s.products, isEmpty);
    final json =
        jsonDecode(
              (await f.db.query('products')).single['json'] as String,
            )
            as Map;
    expect(json['is_active'], isFalse, reason: 'soft delete until synced');
    expect((await outbox()).single['op'], 'delete');

    // The inactive filter still finds it (history).
    bloc.add(const OnProductQuery(inactiveOnly: true));
    final q = await settle((s) => s.queryStatus == ProductQueryStatus.success);
    expect(q.queryResults.map((p) => p.id), [kSynced]);
  });

  test('search reads SQLite', () async {
    await products.create(dto(name: 'Cola'));
    bloc.add(const OnProductQuery(search: 'col'));
    final q = await settle((s) => s.queryStatus == ProductQueryStatus.success);
    expect(q.queryResults.map((p) => p.name), ['Cola']);
  });

  test('M10: an outbox-only change (a push result, a retry) refreshes the '
      'sync markers without re-reading the catalog; a stock change re-reads '
      'it', () async {
    final cache = _CountingCache(f.odb);
    final b = ProductBloc(
      useCase: ProductUseCase(
        repository: ProductRepoImpl(service: () => products),
      ),
      categoryUseCase: CategoryUseCase(
        repository: CategoryRepoImpl(service: () => categories),
      ),
      offlineLocalCache: cache,
      changes: f.notifier.changes,
    );
    addTearDown(b.close);
    final id = await products.create(dto());
    b.add(const OnProductInitial());
    await b.stream.firstWhere(
      (s) => s.productStatus == ProductStatus.success && s.products.length == 2,
    );
    final reads = cache.productReads;
    await f.db.update(
      'outbox',
      {'status': 'rejected', 'error_code': 'conflict_unique'},
      where: 'entity_id = ?',
      whereArgs: [id],
    );
    f.notifier.notify({'outbox'});
    final s = await b.stream
        .firstWhere((s) => s.syncMarks.syncFailed(id))
        .timeout(const Duration(seconds: 5));
    expect(s.products, hasLength(2));
    expect(cache.productReads, reads, reason: 'markers only');
    f.notifier.notify({'stock', 'outbox'});
    for (var i = 0; i < 50 && cache.productReads == reads; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(cache.productReads, reads + 1);
  });

  test('a rejected create shows sync failed', () async {
    final id = await products.create(dto());
    await f.db.update(
      'outbox',
      {'status': 'rejected', 'error_code': 'conflict_unique'},
      where: 'entity_id = ?',
      whereArgs: [id],
    );
    bloc.add(const OnProductInitial());
    final s = await settle(
      (s) => s.productStatus == ProductStatus.success && s.products.length == 2,
    );
    expect(s.syncMarks.syncFailed(id), isTrue);
    expect(s.syncMarks.isPendingSync(id), isFalse);
  });

  test('cashier: add is refused locally, nothing written', () async {
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.cashier,
    );
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final done = submitted();
    bloc.add(OnAddProduct(dto: dto()));
    final s = await done;
    expect(s.submitStatus, ProductSubmitStatus.failure);
    expect(s.submitError, contains('owners and managers'));
    expect(await outbox(), isEmpty);
  });

  test('category created from the product form picker is local', () async {
    bloc.add(const OnProductInitial());
    await settle((s) => s.productStatus == ProductStatus.success);
    final c = Completer<CategoryData?>();
    bloc.add(OnCreateProductCategory(name: 'Snacks', completer: c));
    final created = await c.future;
    expect(created?.name, 'Snacks');
    expect(created?.id, isNotNull);
    expect(bloc.state.categories.map((c) => c.name), contains('Snacks'));
    expect((await outbox()).single['entity'], 'category');
  });
}
