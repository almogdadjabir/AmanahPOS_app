# Notifications

In-app notification history, unread badge, and device token management for AmanaPOS.

---

## Overview

AmanaPOS supports push notifications delivered via Firebase Cloud Messaging (FCM) and an in-app notification inbox. Users can view their notification history, mark individual items as read, and mark all as read. The unread count badge on the bell icon in the app bar updates automatically.

There is **no category concept** in AmanaPOS notifications. Every notification is a flat item with a `type` field that drives its icon and colour in the UI.

---

## File structure

```
lib/features/notification/
├── data/
│   ├── models/
│   │   └── notification_item.dart      ← NotificationItem + NotificationListResponse
│   └── repository_impl/
│       └── notification_repo_impl.dart ← API calls
├── domain/
│   ├── repository/
│   │   └── notification_repository.dart
│   └── usecase/
│       └── notification_usecases.dart
└── presentation/
    ├── bloc/
    │   ├── notification_bloc.dart
    │   ├── notification_event.dart
    │   └── notification_state.dart
    ├── notifications_screen.dart         ← main screen
    └── widgets/
        └── notification_tile.dart        ← single list row

lib/common/services/notifications/
├── fcm_token_service.dart               ← FCM token lifecycle
└── notification_service.dart            ← local notification display
```

---

## API endpoints

All endpoints require the user's Bearer token in the `Authorization` header.

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/v1/notifications/` | Paginated notification history |
| `GET` | `/api/v1/notifications/unread-count/` | Unread count for the badge |
| `PATCH` | `/api/v1/notifications/{id}/read/` | Mark a single notification as read |
| `POST` | `/api/v1/notifications/mark-all-read/` | Mark every notification as read |
| `POST` | `/api/v1/notifications/devices/register/` | Register / update an FCM device token |
| `POST` | `/api/v1/notifications/devices/unregister/` | Remove an FCM device token on logout |

### List query parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Page number (1-based) |
| `page_size` | int | 20 | Items per page |

### List response shape

```json
{
  "count": 42,
  "next": "https://…/api/v1/notifications/?page=2",
  "previous": null,
  "results": [ /* NotificationItem[] */ ]
}
```

### Unread count response

```json
{ "count": 7 }
```

### Mark-read responses

Both mark-read endpoints return `200 OK` on success.

---

## Data model

### `NotificationItem`

```dart
class NotificationItem {
  final String   id;
  final String?  title;
  final String?  body;
  final String   type;     // see Notification types below
  final bool     isRead;
  final DateTime? createdAt;
}
```

The parser accepts both Django-style (`is_read`, `body`) and legacy-style (`read`, `message`) field names for resilience against minor API changes.

### `NotificationListResponse`

```dart
class NotificationListResponse {
  final int              count;
  final String?          next;
  final List<NotificationItem> results;
  bool get hasMore => next != null && next!.isNotEmpty;
}
```

---

## Notification types

| `type` value | Icon | Colour | Badge label |
|---|---|---|---|
| `info` | `info_outline_rounded` | `#0EA5E9` | Info |
| `success` | `check_circle_outline_rounded` | `#16A34A` | Success |
| `warning` | `warning_amber_rounded` | `#F59E0B` | Warning |
| `error` | `error_outline_rounded` | `#EF4444` | Error |
| `sale` | `point_of_sale_rounded` | `#0D9488` | Sale |
| `stock` | `inventory_2_rounded` | `#EC4899` | Stock |
| `subscription` | `card_membership_rounded` | `#8B5CF6` | Plan |
| `security` | `security_rounded` | `#F59E0B` | Security |
| `system` | `settings_rounded` | `#6B7280` | System |

Unknown types fall back to the `info` style.

---

## State management

### Bloc

`NotificationBloc` lives in the root `BlocProvider` list (provided to every screen). It is not a GetIt singleton — it is created fresh per app session.

**Events**

| Event | Trigger | Behaviour |
|---|---|---|
| `OnNotificationInitial({force})` | Screen `initState` or pull-to-refresh | Loads page 1. No-op if already loaded unless `force: true`. |
| `OnLoadMoreNotifications` | Scroll near the bottom | Loads next page and appends to the list. |
| `OnMarkNotificationRead(id)` | Tap on an unread tile | Optimistic: flips `isRead` + decrements `unreadCount` locally, then confirms with the backend. |
| `OnMarkAllNotificationsRead` | "Mark all read" button | Optimistic: marks every item read + sets `unreadCount = 0` locally, then confirms. |
| `OnLoadUnreadCount` | App mount, after any read action | Fetches the authoritative count from `/unread-count/` silently (no loading state, no error). |

**State fields**

| Field | Type | Description |
|---|---|---|
| `status` | `NotificationStatus` | `initial \| loading \| loadingMore \| success \| failure` |
| `notifications` | `List<NotificationItem>` | Accumulates across pages |
| `unreadCount` | `int` | Drives the bell badge in the app bar |
| `currentPage` | `int` | Last successfully fetched page |
| `hasMore` | `bool` | Whether another page exists (`next != null`) |
| `error` | `String?` | Set only on failure |

---

## How the unread count badge works

1. **On app mount** — `OfflinePreparationListener.initState` schedules a post-frame callback that dispatches `OnLoadUnreadCount` when `AuthBloc.state.isLoggedIn` is true. This populates the badge immediately when `MainScreen` appears, before the user opens the notification screen.

2. **On opening the notification screen** — `NotificationsScreen.initState` dispatches `OnNotificationInitial(force: true)`, which on success dispatches `OnLoadUnreadCount` to sync the authoritative count from the backend.

3. **On mark-single-read** — `OnMarkNotificationRead` optimistically decrements `unreadCount` in state. No separate count fetch is needed.

4. **On mark-all-read** — `OnMarkAllNotificationsRead` optimistically sets `unreadCount = 0`.

5. **App bar rendering** — `PosAppBar` uses `BlocSelector<NotificationBloc, NotificationState, int>` (selector: `state.unreadCount`) to rebuild only when the count changes. The `Badge` widget is shown with the numeric count when `count > 0`.

---

## How device token registration works

### At login

`LoginBloc` accepts `fcm_token`, `platform`, `device_name`, `device_id`, and `app_version` as optional payload fields. If the backend login endpoint supports them, the device is registered automatically during authentication.

### On app startup (explicit registration)

`FcmTokenService.initialize()` is called in `main.dart` immediately after `runApp`. It:

1. Retrieves the FCM token from Firebase (with APNs wait on iOS).
2. Checks whether the token was already synced to the backend (via a local cache flag).
3. If unsynced, calls `POST /api/v1/notifications/devices/register/` with the token, platform, device name, device ID, and app version.
4. Subscribes to `FirebaseMessaging.instance.onTokenRefresh` to re-register whenever the token changes.

### On token refresh

`FcmTokenService._handleTokenRefresh` is called automatically. It updates the locally cached token and re-posts to the register endpoint with the new token.

### On logout

`FcmTokenService.unregister()` (called during the logout flow) posts to `POST /api/v1/notifications/devices/unregister/` with the current token. This prevents push notifications from being delivered to a device that is no longer authenticated.

### Device info payload

```json
{
  "fcm_token":    "fcm-token-string",
  "platform":     "android",
  "device_name":  "Samsung Galaxy S22",
  "device_id":    "abc123",
  "app_version":  "1.0.0"
}
```

Device ID and app version are provided by `DeviceInfoService` (native method channel `amana_pos/device_info`).

---

## UI screens

### `NotificationsScreen`

Route: `RouteStrings.notificationsScreen` → `/notifications`

Accessed by tapping the bell icon in `PosAppBar`.

**States shown:**

| State | Widget |
|---|---|
| Loading (first page) | Skeleton shimmer tiles (`_NotificationSkeleton`) |
| Success | `ListView` of `NotificationTile` with pull-to-refresh + infinite scroll |
| Success + empty | `_EmptyView` with icon and message |
| Failure (empty list) | `_ErrorView` with retry button |

**Actions:**

- **Pull-to-refresh** — calls `OnNotificationInitial(force: true)`
- **Scroll to bottom** — triggers `OnLoadMoreNotifications` when within 200 px of the end
- **Tap a tile** — dispatches `OnMarkNotificationRead(item.id)` if the item is unread
- **"Mark all read" button** (visible only when unread count > 0) — dispatches `OnMarkAllNotificationsRead`

### `NotificationTile`

Displays a single notification row:

- **Unread indicator** — 3 px left-border in the type's colour; hidden when read
- **Tile background** — `primaryContainer` at 8 % opacity when unread, normal surface when read
- **Icon badge** — type icon in a circle with 10 % opacity fill
- **Title** — `w900` when unread, `w600` when read
- **Body** — up to 2 lines, truncated with ellipsis
- **Type badge** — small rounded chip (e.g. "Sale", "Stock")
- **Timestamp** — relative: "Just now", "5m ago", "2h ago", "3d ago", or `dd/mm/yyyy`

---

## Dependency injection

| Registration | Type |
|---|---|
| `NotificationRepository` | lazy singleton (`NotificationRepoImpl`) |
| `NotificationUseCases` | lazy singleton |
| `NotificationBloc` | `BlocProvider` in root providers (one per session) |

---

## Foreground push notifications

When the app is in the foreground and a push arrives, `_handleForegroundMessage` in `main.dart` resolves the title and body from `message.notification` (falling back to `message.data`) and calls `NotificationService.instance.show(...)` to display a local notification via `flutter_local_notifications`.

Background and terminated-state pushes are handled natively by the OS using the `notification` payload from FCM. No local notification is shown by the Dart background handler.

---

## Supported notification features (MVP)

| Feature | Status |
|---|---|
| View notification history | ✅ |
| Paginated infinite scroll | ✅ |
| Unread count badge | ✅ |
| Mark single as read | ✅ |
| Mark all as read | ✅ |
| FCM device token registration | ✅ |
| FCM device token unregistration on logout | ✅ |
| Foreground push display (local notification) | ✅ |
| Background / terminated push (OS-native) | ✅ |
| Deep-link navigation from push tap | 🔜 |
| Admin: template management | 🔜 |
| Admin: notification settings (push/SMS limits) | 🔜 |
| Admin: manual send (push / SMS) | 🔜 |
| Admin: delivery logs | 🔜 |
| SMS notifications | 🔜 |
| Reports / analytics | 🔜 |

---

## Planned: admin notification management

The backend already exposes admin APIs. Frontend pages are not yet implemented. When built they should follow the existing AmanaPOS admin screen patterns.

### Templates (`/api/v1/admin/notifications/templates/`)

- List, create, view, update, delete templates
- Fields: `title_en`, `body_en`, `title_ar`, `body_ar`, `variables` (JSON array), `enabled`
- Variables use Python `.format()` syntax — e.g. `{owner_name}`, `{business_name}`
- When editing, render one text input per variable so the sender can fill values before sending

### Settings (`/api/v1/admin/notifications/settings/`)

- `push_enabled` toggle
- `sms_enabled` toggle
- `push_daily_limit` number input
- `sms_daily_limit` number input

### Manual send — push (`/api/v1/admin/notifications/send/push/`)

- User search/select (by name, phone, or business)
- Send as: raw title + body **or** selected template + variable inputs
- Backend handles delivery to all registered devices for the selected user

### Manual send — SMS (`/api/v1/admin/notifications/send/sms/`)

- Same user search/select flow
- Simple: phone number confirmation + message body

### Delivery logs (`/api/v1/admin/notifications/logs/`)

- Table with filters: channel, status, date range, search
- Columns: recipient, channel, type, status, sent-at, error (if failed)
