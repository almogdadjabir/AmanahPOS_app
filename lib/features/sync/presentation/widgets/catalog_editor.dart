import 'dart:async';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_form_screen.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/vendors_sheet.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/product_form_screen.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/widgets.dart';

/// Opens the entity's normal edit form for "Edit and retry" and completes
/// once it is closed AND its save (if any) has been written locally.
typedef CatalogEditorOpener =
    Future<void> Function(
      BuildContext context,
      String entity,
      Map<String, dynamic> json,
    );

/// The app's [CatalogEditorOpener]: the existing product / category /
/// vendor forms (no new screen). The product form uses the app-wide
/// `ProductBloc`; categories and vendors get a short-lived bloc of their own
/// because the pending-sync screen sits outside their feature providers.
Future<void> openCatalogEditor(
  BuildContext context,
  String entity,
  Map<String, dynamic> json,
) async {
  switch (entity) {
    case 'product':
      // The form pops only after its save succeeded.
      await openProductForm(context, product: ProductData.fromJson(json));
    case 'category':
      final bloc = CategoryBloc(
        useCase: getIt<CategoryUseCase>(),
        offlineLocalCache: getIt<OfflineLocalCache>(),
        changes: getIt<DbChangeNotifier>().changes,
      );
      try {
        // The form awaits its save before it pops.
        await openCategoryForm(
          context,
          category: CategoryData.fromJson(json),
          bloc: bloc,
        );
      } finally {
        await bloc.close();
      }
    case 'vendor':
      final bloc = VendorsBloc(
        useCase: getIt<InventoryUseCase>(),
        offlineLocalCache: getIt<OfflineLocalCache>(),
      );
      try {
        final done = bloc.stream.firstWhere(
          (s) =>
              s.submitStatus == VendorsSubmitStatus.success ||
              s.submitStatus == VendorsSubmitStatus.failure,
        );
        final submitted = await showVendorFormSheet(
          context,
          existing: VendorData.fromJson(json),
          bloc: bloc,
        );
        // The vendor sheet pops right after dispatching its save.
        if (submitted == true) {
          await done.timeout(const Duration(seconds: 5));
        } else {
          unawaited(done.then((_) {}, onError: (_) {}));
        }
      } on TimeoutException {
        // Retried anyway below; editAndRetry finds no edit and says so.
      } finally {
        await bloc.close();
      }
  }
}
