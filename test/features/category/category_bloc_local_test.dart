// Phase 3 Task 7: CategoryBloc reads SQLite only and writes through
// CategoryService; category image staging (pending_uploads) is wired here.
import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/features/category/data/repository_impl/category_repo_impl.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const kCat = 'c0000000-0000-4000-8000-000000000001';
const kProd = 'd0000000-0000-4000-8000-000000000001';

void main() {
  late SaleFixture f;
  late CatalogActor actor;
  late Directory base;
  late PendingUploadStore uploads;
  late CategoryService categories;
  late CategoryBloc bloc;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    base = await Directory.systemTemp.createTemp('category_bloc_local');
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
    for (final (id, active) in [(kProd, true), ('p-off', false)]) {
      await f.db.insert('products', {
        'id': id,
        'category_id': kCat,
        'name': 'P $id',
        'stock_level': 0.0,
        'version': 1,
        'json': jsonEncode({
          'id': id,
          'category': kCat,
          'name': 'P $id',
          'is_active': active,
        }),
      });
    }
    bloc = CategoryBloc(
      useCase: CategoryUseCase(
        repository: CategoryRepoImpl(service: () => categories),
      ),
      offlineLocalCache: OfflineLocalCache(f.odb),
      changes: f.notifier.changes,
    );
  });

  tearDown(() async {
    await bloc.close();
    f.notifier.dispose();
    await f.db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  });

  Future<CategoryState> settle(bool Function(CategoryState) test) async {
    if (test(bloc.state)) return bloc.state;
    return bloc.stream.firstWhere(test).timeout(const Duration(seconds: 5));
  }

  /// The NEXT finished submit (call before adding the event).
  Future<CategoryState> submitted() => bloc.stream
      .firstWhere(
        (s) =>
            s.submitStatus == CategorySubmitStatus.success ||
            s.submitStatus == CategorySubmitStatus.failure,
      )
      .timeout(const Duration(seconds: 5));

  Future<PickedAppImage> pick() async {
    final file = File(p.join(base.path, 'picker', 'c.jpg'));
    await file.create(recursive: true);
    await file.writeAsBytes(List.generate(32, (i) => i * 3));
    return PickedAppImage(file: file, path: file.path, name: 'c.jpg');
  }

  test(
    'list shows an unsynced created category without any REST call',
    () async {
      final id = await categories.create(name: 'Snacks');
      bloc.add(const OnCategoryInitial());
      final s = await settle(
        (s) =>
            s.categoryStatus == CategoryStatus.success &&
            s.categoryList.length == 2,
      );
      expect(s.categoryList.map((c) => c.name), ['Drinks', 'Snacks']);
      expect(s.isFromCache, isFalse);
      expect(s.syncMarks.isPendingSync(id), isTrue);
      expect(s.syncMarks.isPendingSync(kCat), isFalse);
    },
  );

  test('add with an image stages a category upload and returns at once; the '
      'create carries image_pending', () async {
    bloc.add(const OnCategoryInitial());
    await settle((s) => s.categoryStatus == CategoryStatus.success);
    final done = submitted();
    bloc.add(OnAddCategory(name: 'Snacks', image: await pick()));
    final s = await done;
    expect(s.submitStatus, CategorySubmitStatus.success);
    final snacks = s.categoryList.singleWhere((c) => c.name == 'Snacks');
    final upload = (await f.db.query('pending_uploads')).single;
    expect([upload['entity'], upload['entity_id']], ['category', snacks.id]);
    final create = (await f.db.query('outbox')).single;
    expect(
      (jsonDecode(create['payload_json'] as String) as Map)['image_pending'],
      true,
    );
  });

  test('edit with only a new image stages it and enqueues nothing', () async {
    final done = submitted();
    bloc.add(
      OnEditCategory(categoryId: kCat, name: 'Drinks', image: await pick()),
    );
    expect((await done).submitStatus, CategorySubmitStatus.success);
    expect(await f.db.query('outbox'), isEmpty);
    final upload = (await f.db.query('pending_uploads')).single;
    expect(upload['entity_id'], kCat);
  });

  test('edit renames locally', () async {
    bloc.add(const OnCategoryInitial());
    await settle((s) => s.categoryStatus == CategoryStatus.success);
    final done = submitted();
    bloc.add(const OnEditCategory(categoryId: kCat, name: 'Juices'));
    final s = await done;
    expect(s.submitStatus, CategorySubmitStatus.success);
    expect(s.categoryList.single.name, 'Juices');
    expect(s.syncMarks.isPendingSync(kCat), isTrue);
  });

  test('delete hides the row at once (refused while it has active '
      'products)', () async {
    bloc.add(const OnCategoryInitial());
    await settle((s) => s.categoryStatus == CategoryStatus.success);
    var done = submitted();
    bloc.add(const OnDeleteCategory(categoryId: kCat));
    var s = await done;
    expect(s.submitStatus, CategorySubmitStatus.failure);
    expect(s.submitError, contains('products'));

    await f.db.delete('products');
    done = submitted();
    bloc.add(const OnDeleteCategory(categoryId: kCat));
    s = await done;
    expect(s.submitStatus, CategorySubmitStatus.success);
    expect(s.categoryList, isEmpty);
    expect((await f.db.query('outbox')).single['op'], 'delete');
  });

  test('deleting a never-sent category with a staged image leaves no upload '
      'or file behind', () async {
    final done = submitted();
    bloc.add(OnAddCategory(name: 'Snacks', image: await pick()));
    final id = (await done).categoryList
        .singleWhere((c) => c.name == 'Snacks')
        .id!;
    await categories.delete(id);
    expect(await f.db.query('pending_uploads'), isEmpty);
    expect(await f.db.query('outbox'), isEmpty);
    final dir = Directory(p.join(base.path, 'pending_images'));
    expect(
      dir.existsSync() ? dir.listSync(recursive: true).whereType<File>() : [],
      isEmpty,
    );
  });

  test('category products come from SQLite, inactive hidden', () async {
    bloc.add(const OnLoadCategoryProducts(categoryId: kCat));
    final s = await settle(
      (s) => s.productsStatus == CategoryProductsStatus.success,
    );
    expect(s.products.map((p) => p.id), [kProd]);
    expect(s.productsFromCache, isFalse);
    expect(s.hasMorePages, isFalse);
  });

  test('cashier: add is refused, nothing written', () async {
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.cashier,
    );
    final done = submitted();
    bloc.add(const OnAddCategory(name: 'Snacks'));
    final s = await done;
    expect(s.submitStatus, CategorySubmitStatus.failure);
    expect(await f.db.query('outbox'), isEmpty);
  });
}
