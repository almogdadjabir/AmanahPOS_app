# Categories

## Files

```
lib/features/category/
├── data/
│   ├── models/
│   │   ├── requests/
│   │   │   ├── add_category_request_dto.dart
│   │   │   └── edit_category_request_dto.dart
│   │   └── responses/
│   │       ├── add_category_response_dto.dart
│   │       └── category_response_dto.dart       ← CategoryResponseDto + CategoryData
│   └── repository_impl/category_repo_impl.dart
├── domain/
│   ├── repositories/category_repository.dart
│   └── usecases/category_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── category_bloc.dart
    │   ├── category_event.dart   ← part of category_bloc.dart
    │   └── category_state.dart   ← part of category_bloc.dart
    ├── category_screen.dart      ← CategoriesScreen
    ├── category_detail_screen.dart
    └── widgets/
        ├── add_category_sheet.dart    ← showAddCategorySheet(context)
        ├── edit_category_sheet.dart
        ├── delete_category_sheet.dart
        └── ...
```

## Key Models

### `CategoryData` (in `category_response_dto.dart`)

```dart
String?           id
String?           name
String?           description
String?           image
String?           thumbnailUrl
bool?             isActive
int?              sortOrder
List<CategoryData>? children    // nested sub-categories
String?           createdAt
String?           updatedAt
```

### `AddCategoryRequestDto`

```dart
String? name
String? description
```

### `AddCategoryResponseDto`

```dart
bool?         success
String?       message
CategoryData? data       // the newly created category
```

## CategoryUseCase Methods

```dart
getCategories()
    → Either<String?, CategoryResponseDto>

addCategory(AddCategoryRequestDto)
    → Either<String?, AddCategoryResponseDto>

editCategory(String categoryId, EditCategoryRequestDto)
    → Either<String?, bool>

deleteCategory(String categoryId)
    → Either<String?, bool>
```

## CategoryBloc

**Constructor deps:**
```dart
CategoryUseCase    useCase
ProductUseCase     productUseCase
OfflineLocalCache  offlineLocalCache
```

**Registered in:** `lib/config/providers/providers.dart` (not GetIt singleton).

### CategoryState

```dart
CategoryStatus        categoryStatus   // initial | loading | success | failure
CategorySubmitStatus  submitStatus     // initial | loading | success | failure
List<CategoryData>    categoryList
bool                  isFromCache
String?               responseError
String?               submitError

// Category detail / products sub-state:
CategoryProductsStatus productsStatus  // initial | loading | loadingMore | success | failure
List<ProductData>      products
int                    currentPage
int                    totalPages
bool                   productsFromCache
String?                productsError

bool get hasMorePages => currentPage < totalPages;
```

### Events

| Event | Trigger |
|---|---|
| `OnCategoryInitial({bool force = false})` | Screen init |
| `OnAddCategory({String name, String? description, String? parentId})` | Submit add sheet |
| `OnEditCategory({String categoryId, String name, String? description})` | Submit edit sheet |
| `OnToggleCategoryActive({String categoryId})` | Toggle (currently no-op in MVP) |
| `OnLoadCategoryProducts({String categoryId})` | Entering category detail |
| `OnLoadMoreCategoryProducts({String categoryId})` | Paginate in detail |
| `OnDeleteCategory({String categoryId})` | Confirm delete |
| `OnCategoryReset()` | User session switch (dispatched from OfflinePreparationListener) |

### `_addCategory` Result

On success, the new `CategoryData` from `AddCategoryResponseDto.data` is appended to `state.categoryList`.
If `parentId` is provided, it is inserted into the matching parent's `children` list.

### `_reset` Flow

```dart
emit(CategoryState.initial());
add(const OnCategoryInitial());
```

## `showAddCategorySheet(context)`

Modal bottom sheet. Fields: name (required), description (optional).
On submit dispatches `OnAddCategory`.
`BlocListener` on `submitStatus`:
- `success` → pop + snackbar
- `failure` → snackbar with error

## Relationship with ProductBloc

`ProductBloc._init` also calls `useCase.getCategories()` in parallel and stores them in `ProductState.categories`. This is used by:
- Category filter chips in the product screen.
- The `CategoryPicker` inside `add_product_sheet.dart`.

So category data lives in **both** `CategoryBloc.state.categoryList` and `ProductBloc.state.categories`. They are loaded independently.
