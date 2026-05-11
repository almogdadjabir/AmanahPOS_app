# POS

## Files

```
lib/features/pos/
├── data/
│   ├── datasources/pos_remote_data_source.dart
│   ├── model/
│   │   ├── pos_cart_item.dart
│   │   └── offline/offline_sales_queue.dart   ← SQLite queue for offline sales
│   └── repository_impl/pos_repo_impl.dart
├── domain/
│   ├── repositories/pos_repository.dart
│   └── usecases/pos_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── pos_bloc.dart
    │   ├── pos_event.dart   ← part of pos_bloc.dart
    │   └── pos_state.dart   ← part of pos_bloc.dart
    └── pos_screen.dart
```

## PosBloc

**Constructor deps:** `PosUseCase useCase`

**Registered in:** `lib/config/providers/providers.dart`.

### PosState (key fields)

```dart
List<PosCartItem>   cartItems
String?             searchQuery
String?             selectedCategoryId
PaymentMethod       paymentMethod
bool                isCartExpanded
String?             selectedShopId
String?             selectedShopName
PosSubmitStatus     submitStatus   // idle | loading | success | failure
String?             submitError
```

### Events

| Event | Effect |
|---|---|
| `PosSearchChanged(query)` | Update search query |
| `PosCategoryChanged(categoryId)` | Filter products by category; null = all |
| `PosPaymentMethodChanged(method)` | Cash / card / etc. |
| `PosAddProduct(product)` | Add to cart or increment quantity |
| `PosIncrementItem(productId)` | +1 quantity |
| `PosDecrementItem(productId)` | -1 quantity; removes if reaches 0 |
| `PosRemoveItem(productId)` | Remove from cart |
| `PosClearCart()` | Empty the cart |
| `PosCheckoutSubmitted()` | Submit sale (online → API, offline → queue) |
| `PosAcknowledgeSubmit()` | Reset submit status after showing receipt |
| `PosCartExpandedChanged(expanded)` | Toggle cart panel |
| `PosShopSelected(shopId, shopName)` | Select active shop |

### Checkout Flow

`PosRepoImpl` handles online/offline routing:
- Online → `PosRemoteDataSource.createSale(...)` → API.
- Offline → `OfflineSalesQueue.enqueue(sale)` → SQLite.

After successful checkout, `PosBloc` dispatches `OnProductsSoldLocally` to `ProductBloc` to reduce stock in-memory without waiting for a full refresh.

## OfflineSalesQueue

SQLite table for pending sales.

```dart
Future<void> enqueue(OfflineSaleEntry sale)
Future<List<OfflineSaleEntry>> getPendingSales({int limit})
Future<void> markSyncing(String clientSaleId)
Future<void> markSynced({required String clientSaleId})
Future<int> pendingCount()
```

`SyncManager.syncPendingSales()` reads this queue and posts to the API in batches.
Synced sales are removed from the queue.
