# AmanaPos — Codebase Docs

Flutter POS app. Offline-first. BLoC pattern throughout. GetIt for DI.

## Doc Index

| File | What it covers |
|---|---|
| [architecture.md](./architecture.md) | App-wide structure, DI, routing, providers |
| [auth.md](./auth.md) | AuthBloc, session management, permissions |
| [navigation.md](./navigation.md) | NavigationBloc, feature menu, screen switching |
| [offline.md](./offline.md) | Offline-first system, OfflineStatusBloc, sync |
| [products.md](./products.md) | ProductBloc, product screen, add/edit/delete |
| [categories.md](./categories.md) | CategoryBloc, category screen |
| [pos.md](./pos.md) | PosBloc, cart, checkout, offline sales queue |
| [conventions.md](./conventions.md) | Code style rules — read before touching anything |

## Tech Stack

- Flutter (Dart)
- `flutter_bloc` — all state management
- `get_it` — dependency injection (singleton `getIt`)
- `dio` — HTTP client
- `sqflite` — local SQLite DB for offline cache
- `fpdart` — `Either<String?, T>` for all repo responses
- `equatable` — value equality on blocs/events/states
- `connectivity_plus` — network monitoring
