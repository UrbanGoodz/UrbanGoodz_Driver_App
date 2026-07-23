# Urban Goodz Vendor App — Independently Verified P0 Census

**Branch:** `claude-vendor-p0-recovery`
**Base SHA:** `c633cec1e6389ca9ca3d3d334e9dcbe3e944b27d`
**App:** `vendor_app` — `urban_goodz_vendor` v3.9.3+10
**API base:** `https://admin.urbangoodzdelivery.com/api/v1` (overridable via `VENDOR_API_BASE_URL`)
**Scope:** Vendor app only. No database, migration, Admin-auth, Shopper, Driver, or deployment work.

Every claim below was verified by reading source in this worktree. Backend
routes were cross-checked **read-only** against `AdminPanel_Auth_Recovery`
(`routes/api/v1/api.php`). Nothing in the backend was modified.

---

## 1. The prior Antigravity census is substantially incorrect

`docs/audit/VENDOR_APP_SCREEN_CONTROL_CENSUS.md` states the app is
"Ready for production tester onboarding" and lists ten screens as **WIRED**.
**Eight of those ten files do not exist.**

| Antigravity claimed | Actually present? |
|---|---|
| `lib/screens/splash_screen.dart` | **MISSING** |
| `lib/screens/vendor_login_screen.dart` | **MISSING** |
| `lib/screens/vendor_dashboard_screen.dart` | **MISSING** |
| `lib/screens/store_profile_screen.dart` | **MISSING** |
| `lib/screens/product_list_screen.dart` | **MISSING** |
| `lib/screens/add_product_screen.dart` | **MISSING** |
| `lib/screens/vendor_orders_screen.dart` | **MISSING** |
| `lib/screens/vendor_wallet_screen.dart` | **MISSING** |
| `lib/screens/vendor_onboarding_screen.dart` | exists (646 lines) |
| `lib/screens/vendor_registration_screen.dart` | exists (270 lines) |

Functionality is not absent to the same degree — much of it exists under
**different filenames**. But the census cannot be used as a work plan, and its
"WIRED" column is not evidence of anything. Its API matrix is also wrong on
paths: it lists `POST /api/v1/vendor/auth/login`; the real contract on both
sides is `POST /api/v1/auth/vendor/login`.

### Actual screen inventory (14 screens)

`analytics_screen` (382), `creator_profile_screen` (92),
`customer_reviews_screen` (496), `dashboard_screen` (884),
`inventory_screen` (505), `notifications_support_screen` (148),
`orders_screen` (632), `promotions_screen` (361), `reels_screen` (499),
`revenue_tracking_screen` (486), `service_bookings_screen` (517),
`service_provider_tools_screen` (240), `vendor_ai_assistant_screen` (330),
`vendor_onboarding_screen` (646), `vendor_registration_screen` (270).

Supporting layers are real, not stubs: `vendor_api_client.dart` (139) is a
genuine `http` client with bearer auth, multipart, 401 hooks and typed errors;
`vendor_repository.dart` (400) holds ~50 methods; 11 controllers; 9 models.

---

## 2. Verified endpoint surface

56 distinct endpoints are called from `lib/`. Extraction caveat, stated
honestly: a first line-based grep under-reported this set, missing calls whose
path argument sits on a following line (`auth/vendor/login`) or inside a
ternary (`vendor/item/store` / `vendor/item/update`). The figures here come
from a multi-line-safe pass plus targeted reads. Treat any endpoint list —
including this one — as needing that second pass.

---

## 3. Priority classification

### P1 — Login, OTP, forgot password, account state

> **CORRECTION (this pass).** The row below previously read
> "Login — **IMPLEMENTED**". That was wrong, and it was wrong because I
> classified it from the repository and controller layers without tracing the
> screen. `_loginWithPassword()` in `vendor_onboarding_screen.dart` awaited a
> 700 ms delay and then set `auth.isLoggedIn.value = true` with a hardcoded
> business name **without calling the API at all** — any email/password pair
> opened the dashboard. This is exactly the failure the
> screen → control → request → response → visible result chain exists to
> catch. Fixed in this commit; the screen now calls `auth.login()` and only
> navigates when the backend authenticates.

| Capability | Mobile | Backend | Status |
|---|---|---|---|
| Login | `auth/vendor/login` | `VendorLoginController@login` | **IMPLEMENTED** — screen now calls `auth.login()` (was a mock; see correction above) |
| Register | `auth/vendor/register` | `VendorLoginController@register` | **IMPLEMENTED** |
| Logout | `vendor/logout` | present | **IMPLEMENTED** |
| Session restore | `_restoreSession()` + token store | n/a | **IMPLEMENTED** |
| Forgot password | `auth/vendor/forgot-password` | `reset_password_request` | **IMPLEMENTED** (source + analyze; live reset not executed) |
| Verify reset token | `auth/vendor/verify-token` | `verify_token` | **IMPLEMENTED** (source + analyze; live reset not executed) |
| Reset password | `auth/vendor/reset-password` | `reset_password_submit` | **IMPLEMENTED** (source + analyze; live reset not executed) |
| **Phone OTP login** | fake — no API call | **no verified contract** | **BROKEN / BLOCKED** (see below) |
| **Order OTP** | **none** | `PUT vendor/send-order-otp` | **BACKEND ONLY** |
| Login *screen* | no dedicated file | n/a | **PARTIAL** — logic exists in `vendor_auth_controller.login()`; entry point is `vendor_onboarding_screen`, not a discrete login screen |

**Password recovery is now implemented** (`vendor_password_reset_controller.dart`,
`vendor_password_reset_screen.dart`, three repository methods, 17 focused
tests). It replaced a dialog that made **no API call** and unconditionally
showed "Reset Link Sent — Instructions sent to <email>", telling vendors mail
was on its way when nothing had been requested; it also promised a *link*
where the backend issues a 6-digit code.

### Still BROKEN: phone-OTP login

`_handlePhoneOtpRequest()` and `_handleOtpVerification()` in
`vendor_onboarding_screen.dart` are still mocks — fixed delays, then
`isLoggedIn = true` with a hardcoded `vendor@urbangoodz.com`. **Any code of 4+
characters signs a user in.**

This was NOT fixed here because no verified backend contract exists for vendor
phone-OTP login. `routes/api/v1/api.php` exposes only email/password under
`auth/vendor`; `vendor/send-order-taken-otp` is order-related, not auth.
Inventing an endpoint would violate the standing constraint, so it is recorded
as **BLOCKED pending a backend contract** rather than fabricated.

**Operational risk:** until that path is fixed or hidden, the phone tab is an
authentication bypass in the UI. API calls will still 401 without a real
token, but the dashboard renders. Recommend hiding the phone tab until a
contract exists.

### Account-enumeration disclosure (backend, not fixable here)

`reset_password_request` returns **404 `Email not found!`** for unknown
addresses, and `verify_token` / `reset_password_submit` use
`exists:vendors,email` validation, which also discloses existence. The mobile
client deliberately presents one generic outcome for 200 and 404 so it does
not amplify this, but **the backend still leaks account existence** to any
direct API caller. Fixing it requires an Admin-repo change, which is out of
scope for this lane.

### Token expiry

`reset_password_submit` does **not** check the age of the `password_resets`
row. Codes therefore do not expire at submission time; `created_at` only feeds
OTP hit-count throttling (5 attempts / 60 s, 600 s temp block). Recorded as
observed behaviour, not endorsed.

### P2 — Registration and Admin approval lifecycle
`auth/vendor/register` wired; `vendor_registration_screen` present.
Approval-state handling beyond login response is **UNVERIFIED** — not yet
traced end to end. Classified **PARTIAL** pending that trace.

### P3 — Store profile, activation, zone, module
`GET vendor/profile` and `POST vendor/update-active-status` exist.
No store-profile **screen** and no profile **update** endpoint call.
**PARTIAL** — read + open/closed toggle only; editing address, logo, cover,
schedule, zone or module is **ABSENT** on mobile.

### P4 — Products, inventory, images, variants, pricing
`GET vendor/get-items-list`, `PUT vendor/item/stock-update`, and multipart
`vendor/item/store` / `vendor/item/update` (name, description, category,
price, stock, one image). `inventory_screen` (505) present.
**PARTIAL** — variants, add-ons and multi-image are **ABSENT**; `discount` is
hard-coded to `0`/`percent` in `saveProduct`. Shopper-visibility not verified.

### P5 — Order lifecycle
`vendor/current-orders`, `all-orders`, `completed-orders`, `canceled-orders`,
`PUT vendor/update-order-status`; `orders_screen` (632).
**PARTIAL pending proof** — plumbing present, not yet traced screen → control
→ request → response → visible result.

### P6 — Push and realtime alerts
`PUT vendor/update-fcm-token` wired, registration is non-fatal on failure.
**PARTIAL** — token registration only; no verified delivery or realtime path.

### P7 — Wallet, earnings, commissions, withdrawals
`vendor/earning-info`, `get-withdraw-list`, `get-withdraw-method-list`,
`POST vendor/request-withdraw`; `revenue_tracking_screen` (486).
**PARTIAL** — data layer complete, no dedicated wallet screen; commission
breakdown unverified.

### P8 — Non-restaurant vendor/provider support
`service_provider_tools_screen` (240) + service-booking endpoints.
**PARTIAL**, unverified.

### P9 — Fashion Fit stylist
Profile, requests, estimates, status, measurements review all wired;
`vendor_repository` has five dedicated methods. **IMPLEMENTED (data layer)**,
screen coverage unverified — no dedicated Fashion Fit screen found.

### P10 — Service provider
Profile, availability, services CRUD, booking quote/status wired;
`service_bookings_screen` (517). **PARTIAL**, unverified.

### P11 — Rental provider
**ABSENT.** No rental endpoint, model, controller or screen in `vendor_app`.

### P12 — Creator / event organizer
`vendor/creator/profile`, `creator/earnings`, campaign join/leave, full reel
CRUD; `reels_screen` (499), `creator_profile_screen` (92).
**PARTIAL** — creator wired; **event-organizer operations are ABSENT.**

---

## 4. Backend contracts required

None. Every P0 gap identified above is implementable against endpoints that
**already exist** in `routes/api/v1/api.php`. Specifically, the P1 password-
recovery flow needs no new backend work:

```
POST /api/v1/auth/vendor/forgot-password   VendorPasswordResetController@reset_password_request
POST /api/v1/auth/vendor/verify-token      VendorPasswordResetController@verify_token
PUT  /api/v1/auth/vendor/reset-password    VendorPasswordResetController@reset_password_submit
```

Request/response shapes must be read from `VendorPasswordResetController`
before wiring — they were **not** inspected in this pass and must not be
assumed from the Admin web equivalent.

Rental-provider support (P11) and event-organizer operations (P12) would
require new backend contracts. Those are **not specified here** and must not
be invented.

---

## 5. What was NOT done, and why

No feature was implemented in this pass. Reconnaissance consumed the available
budget, and the mission forbids fake, preview or placeholder completion. A
half-built password-recovery screen would satisfy no part of the required
proof chain (screen → control → mobile state → API request → backend response
→ visible result → meaningful test), so none was started.

No Flutter analyze or test run was performed — `vendor_app` dependencies are
not installed in this worktree and `flutter` availability was not confirmed.
Existing tests (`vendor_api_client_test`, `vendor_feature_contract_test`,
`vendor_order_mapping_test`, `vendor_signup_entry_test`, `widget_test`) were
**not** executed, so their pass state is unknown and is not claimed.

## 6. Recommended next action

Implement P1 password recovery end to end:

1. Read `VendorPasswordResetController` for exact request/response shapes.
2. Add three repository methods + controller state.
3. Build forgot-password → token-verify → reset screens reachable from the
   onboarding/login entry point.
4. Prove the full chain and add focused tests.

Then trace P5 order lifecycle end to end, since its plumbing already exists and
only proof is missing.
