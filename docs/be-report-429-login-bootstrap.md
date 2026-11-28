# Backend report: 429 "Too many requests" on login + first data download (mobile)

Reporter: mobile app (Flutter), 2026-11-28. Needs the backend agent to check the throttles below.

## What the owner saw (in order)
1. Opened the app with an EXPIRED session. Expected: back to login. Actual: the "Add business" screen.
2. Closed and reopened: login screen appeared (correct). Logged in OK.
3. "Downloading business data" screen, then an error: `429 : Too many requests`. The app then stopped.

## Mobile-side causes (already fixed in the app, for context)
- (1) was a client bug: an expired session was read as "this user has 0 businesses". Fixed; not a backend issue.
  The backend did correctly answer 401 / failed refresh.
- (3) The first-time download did not wait on 429: it stopped instead. Fixed: the app now waits `Retry-After`
  (or 2s, 4s, 8s... up to 60s, max 6 tries) and resumes from its cursor.
  That makes the app polite, but the 429 itself still comes from the server, so please check the items below.

## What the backend should check / change
1. **Which throttle fired?** Login + first setup is a burst from ONE user/device:
   `auth/otp/verify` -> `auth/token/refresh` -> `GET sync/ping` -> `GET sync/bootstrap/` manifest ->
   N x `GET sync/bootstrap/` pages (page size 500, one request per page per entity, up to ~15 entities,
   no client delay between pages) -> `GET sync/assets/...` -> REST: `tenants/businesses/`, `subscriptions/features/`,
   profile, shops. Please confirm which scope/rate returned 429 (the response body/`Retry-After`).
2. **Are `sync/bootstrap` page calls throttled like the legacy `offline/bootstrap` (12/min)?**
   The legacy monolithic call is 12/min per user; the paged `?section=` mode is 240/min. A big tenant needs
   far more than 12 page requests in a minute only if it is the unpaged limit. Please confirm `sync/bootstrap/`
   uses the high (paged) limit, and that its limit is per user+device, not per IP (many shops share one NAT IP in Sudan).
3. **Token refresh / OTP throttles**: the summary says auth throttling is being reworked. A user who just
   logged in must not be 429'd by refresh. Please exempt a refresh that follows a login from the anon/IP throttle.
4. **Always send `Retry-After`** (seconds) on every 429, plus the typed body
   `{"success":false,"error":{"code":"rate_limited","message":"...","retry_after":N}}`.
   The mobile sync client reads `error.retry_after`, `retry_after`, and the `Retry-After` header; the plain REST
   client currently shows only "429 : Too many requests" with no wait time.
5. **Expired session must be a clean 401** (`token_expired` / `token_not_valid`), never 429, so the app can log out.
   If refresh is 429'd on a dead token the app cannot tell "expired" from "busy".

## How to reproduce
Fresh login on a tenant with a lot of data (many products/customers/sales), on a real network, then watch the
first-setup screen. Capture the server log for the user's requests in that minute and the throttle class name.
