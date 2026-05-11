# Products

## Files

```
lib/features/products/
├── data/
│   ├── model/
│   │   ├── request/
│   │   │   ├── add_product_request_dto.dart
│   │   │   └── update_product_request_dto.dart
│   │   └── response/
│   │       ├── add_product_response_dto.dart
│   │       ├── category_products_response_dto.dart  ← also contains ProductData
│   │       └── product_response_dto.dart
│   └── repository_impl/product_repo_impl.dart
├── domain/
│   ├── repositories/product_repository.dart
│   └── usecases/product_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── product_bloc.dart
    │   ├── product_event.dart   ← part of product_bloc.dart
    │   └── product_state.dart   ← part of product_bloc.dart
    ├── product_screen.dart
    ├── product_detail_screen.dart
    └── widgets/
        ├── add_product_sheet.dart
        ├── edit_product_sheet.dart
        ├── delete_product_sheet.dart
        ├── category_filter.dart
        ├── category_picker.dart
        ├── product_empty_view.dart
        ├── product_error_view.dart
        ├── product_loading_view.dart
        ├── products_body.dart
        └── ...
```

## Key Models

### `ProductData` (in `category_products_response_dto.dart`)

```dart
String? id
String? category       // category ID
String? categoryName
String? name
String? price
String? costPrice
String? unit
bool?   trackInventory
double? stockLevel
double? minStockLevel
String? sku
String? barcode
String? thumbnailUrl
```

### `AddProductRequestDto`

```dart
required String name
required String price
required String category   // category ID — must be a valid ID
required String unit
required bool   trackInventory
String? costPrice
String? description
String? sku
String? barcode
String? minStockLevel
PickedAppImage? imageUpload
```

## ProductUseCase Methods

```dart
getProducts({required int page, int pageSize = 20})
    → Either<String?, ProductListResponseDto>

getProductsByCategory({required String categoryId, required int page})
    → Either<String?, CategoryProductsResponseDto>

getCategories()
    → Either<String?, CategoryResponseDto>

addProduct(AddProductRequestDto)
    → Either<String?, AddProductResponseDto>

editProduct(String productId, UpdateProductRequestDto)
    → Either<String?, bool>

deactivateProduct(String productId)
    → Either<String?, bool>
```

## ProductBloc

**Constructor deps:** `ProductUseCase useCase`, `OfflineLocalCache offlineLocalCache`

**Registered in:** `lib/config/providers/providers.dart` (not GetIt singleton).

### ProductState

```dart
ProductStatus       productStatus     // initial | loading | loadingMore | success | failure
ProductSubmitStatus submitStatus      // initial | loading | success | failure
List<ProductData>   products
List<CategoryData>  categories        // for the category filter chips
String?             selectedCategoryId
int                 currentPage
int                 totalPages
bool                isGrid
bool                isFromCache
String?             responseError
String?             submitError

bool get hasMorePages => currentPage < totalPages;
```

### Events

| Event | Trigger |
|---|---|
| `OnProductInitial({bool force = false})` | Screen init, pull-to-refresh |
| `OnProductCategorySelected({String? categoryId})` | Category chip tap; null = All |
| `OnLoadMoreProducts()` | Scroll near bottom |
| `OnToggleProductLayout()` | Grid/list toggle button |
| `OnAddProduct({AddProductRequestDto dto})` | Submit add product sheet |
| `OnUpdateProduct({String productId, UpdateProductRequestDto dto})` | Submit edit sheet |
| `OnDeleteProduct({String productId})` | Confirm delete |
| `OnProductsSoldLocally({Map<String, int> soldQuantities})` | POS checkout (offline stock reduction) |
| `OnProductReset()` | User session switch (dispatched from OfflinePreparationListener) |

### `_init` Flow

```
1. offlineLocalCache.getProducts() + getCategories()
   → not empty: emit success (isFromCache: true)
   → empty: emit loading, products: [], categories: []
2. Future.wait([useCase.getProducts(page:1), useCase.getCategories()])
3. Success path:
   → saveProductsToCache() + saveCategoriesToCache()
   → getProducts() + getCategories() (normalized from SQLite)
   → emit success (isFromCache: false)
4. Error + had cache → emit success with responseError (show cache, soft error)
   Error + no cache  → emit failure
```

### `_addProduct` Flow

```
1. emit submitStatus: loading
2. useCase.addProduct(dto)
3. Success: emit submitStatus: success, prepend product to state.products
4. Failure: emit submitStatus: failure, submitError: error
```

On success, `BlocListener` in `add_product_sheet.dart` pops the sheet and shows a snackbar.

## ProductsScreen (`product_screen.dart`)

`ProductsScreen({bool isWithAppbar = false})`

Usage:
- `isWithAppbar: false` — inside `MainScreen` (no back button, no appbar).
- `isWithAppbar: true` — pushed as named route `RouteStrings.productScreen`.

Screen states:
```
loading/initial         → ProductLoadingView
failure                 → ProductErrorView
success + has products  → _ProductsContent (NestedScrollView + CategoryFilter + ProductsBody)
success + empty         → _ProductsEmptyContent
```

`_ProductsEmptyContent` renders `ProductEmptyView` with:
- `hasCategories: state.categories.isNotEmpty`
- When `false`: title = "Create a category first", button = "Add Category"
- When `true`: title = "No products yet", button = "Add Product"

`_openEmptyAction` (pre-fix):
```dart
void _openEmptyAction(ProductState state) {
  if (state.categories.isEmpty) {
    showAddCategorySheet(context);
    return;
  }
  showAddProductSheet(context);
}
```

## Add Product Sheet (`add_product_sheet.dart`)

Called via `showAddProductSheet(BuildContext context)`.

Local state:
```dart
CategoryData?   _selectedCategory   // null if no categories exist
String          _selectedUnit = 'pcs'
bool            _trackInventory = true
PickedAppImage? _pickedImage
```

`initState` pre-selects `state.categories.first` if list is not empty.

Current `_submit` guard:
```dart
if (_selectedCategory == null) {
  GlobalSnackBar.show(message: 'Please select a category', isError: true);
  return;
}
```

`BlocListener` handles `submitStatus`:
- `success` → `Navigator.pop()` + snackbar "Product added successfully"
- `failure` → snackbar with `state.submitError`

## Units (`lib/config/enum.dart`)

```dart
const kUnitsShop       = ['pcs', 'kg', 'g', 'l', 'ml', 'box', 'pack'];
const kUnitsRestaurant = ['pcs', 'portion', 'plate', 'bowl', 'glass', 'bottle'];
```

Sheet uses `isRestaurant` from `AuthBloc.state.permissions.isRestaurant` to pick the list.
