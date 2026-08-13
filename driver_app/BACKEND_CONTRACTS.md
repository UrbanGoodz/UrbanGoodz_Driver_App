# Driver App — Backend Contract Requests

For Claude 3 (backend/database lane). Raised from the Driver P0 pass on
2026-07-23. Every item below was checked against the live backend at
`https://admin.urbangoodzdelivery.com` before being written down.

## How routes were verified

This backend distinguishes itself usefully:

| Response | Meaning |
|---|---|
| `401` + `{"errors":[{"code":…,"message":…}]}` | route exists, auth required |
| `403` + `{"errors":[{"code":"<field>",…}]}` | route exists, validation failed |
| `405` "Supported methods: GET, HEAD" | route **does not exist** |
| `429` + `{"message":"Too Many Attempts."}` | throttled (login: 5 attempts) |

So a `401` proves a route is deployed; a `405` proves it is not.

### Confirmed deployed (401 without a token)

`/api/v1/delivery-man/profile`, `/api/v1/delivery-man/update-active-status`,
`/api/v1/delivery-man/record-location-data`,
`/api/v1/delivery-man/update-fcm-token`, and all of
`/api/v1/urban-goodz/driver/{business-jobs, active-jobs, job-discovery,
load-board, opportunities, earnings, payout-history, routes, certifications,
dispatch-notifications, capability-profile, capability-summary, vehicles}`.

### Confirmed absent (405)

`/api/v1/auth/delivery-man/otp`, `/api/v1/auth/delivery-man/verify-otp`,
`/api/v1/auth/send-otp`. The driver app's OTP sign-in and self-service
password reset have been removed accordingly.

---

## BLOCKER-0 — A working test driver account

Not a contract change, but it gates verification of every item below.

Without credentials for an approved driver on this backend, the following
could not be confirmed against a live 200 response, only against the app's
existing conventions:

- the success shape of `POST /api/v1/auth/delivery-man/login` (the `token`
  field name is assumed from existing app code);
- the field names accepted by `record-location-data` (see CONTRACT-2);
- the `allowed_values.vehicle_types` vocabulary served by
  `capability-profile` (see CONTRACT-3);
- every status transition in the marketplace delivery lifecycle.

**Requested:** one approved driver and one *pending-approval* driver account
on the live backend, so account-state handling can be tested rather than
inferred.

---

## CONTRACT-1 — Fix the "Bycycle" spelling at its source

```
FEATURE:            Vehicle type vocabulary
METHOD:             GET
PATH:               /api/v1/get-vehicles
REQUEST:            none (public)
RESPONSE:           [{id, type, image_full_url, translations[], storage[]}]
AUTH:               none
PERMISSION:         public
TABLES:             dm_vehicles, translations
STATUS TRANSITIONS: none
NOTIFICATION:       none
PAYOUT EFFECT:      none
ACCEPTANCE TEST:    GET /api/v1/get-vehicles returns no row whose `type` or
                    whose translation `value` is "Bycycle".
```

**The defect is in the database, not in the app.** Live response today:

```json
[{"id":1,"type":"bike",...,"translations":[{"id":169,...,"value":"bike"}]},
 {"id":2,"type":"car",...,"translations":[{"id":170,...,"value":"car"}]},
 {"id":3,"type":"Bycycle",...,"translations":[{"id":171,...,"value":"Bycycle"}]}]
```

The driver app hardcodes no vehicle list — `driver_registration_screen.dart`
renders whatever this endpoint returns. The misspelling therefore cannot be
corrected in Flutter without lying about the stored value, and was
deliberately left alone.

Two rows need fixing, and both must change together or the API keeps serving
the typo through the translation:

1. `dm_vehicles` where `id = 3` → `type` = `bicycle`
2. `translations` where `id = 171` (`translationable_type =
   'App\Models\DMVehicle'`, `translationable_id = 3`, `key = 'type'`)
   → `value` = `bicycle`

Note the casing is also inconsistent: `bike` and `car` are lowercase while
`Bycycle` is capitalised. Recommend lowercase `bicycle` for consistency.

Also confirm whether any `delivery_men.vehicle_id = 3` rows exist; the id is
unchanged so they are unaffected, but the display name they inherit changes.

---

## CONTRACT-2 — Document the location payload and echo it back

```
FEATURE:            Driver location reporting (driver availability)
METHOD:             POST
PATH:               /api/v1/delivery-man/record-location-data
REQUEST:            UNKNOWN — please confirm. The app currently sends:
                      {latitude: <double>, longitude: <double>,
                       location_timestamp: <ISO-8601 UTC>,
                       accuracy: <double, optional>}
RESPONSE:           requested: {latitude, longitude, recorded_at, is_stale}
AUTH:               ?token= query parameter (dm.api middleware)
PERMISSION:         approved, active delivery man
TABLES:             delivery_man_locations (?), delivery_men
STATUS TRANSITIONS: none directly; feeds availability/dispatch eligibility
NOTIFICATION:       none
PAYOUT EFFECT:      none
ACCEPTANCE TEST:    POST a fix, then GET /api/v1/delivery-man/profile and
                    observe the same coordinates with a recorded_at within
                    one minute of now.
```

**Why this matters:** this is the fix for *"Admin shows 3 drivers but 0
available."* The driver app never called this route at all — the constant
existed in `api_config.dart` and was referenced nowhere, the app had no
location dependency, and the Android manifest requested no location
permission. The backend had a `delivery_man` row per driver but no position
for any of them.

The app now reports positions, but the request body could not be validated
against a live 200 (see BLOCKER-0). If the accepted field names differ,
uploads will be silently discarded and the symptom will persist. Please
confirm the exact schema, and ideally return the stored values so the client
can verify acceptance rather than assume it.

---

## CONTRACT-3 — Publish the supported vehicle and capability vocabulary

```
FEATURE:            Driver capability profile allowed values
METHOD:             GET
PATH:               /api/v1/urban-goodz/driver/capability-profile
REQUEST:            none
RESPONSE:           {profile: {...}, allowed_values: {vehicle_types: [...],
                    work_types: [...], capability_tags: [...], zones: [...]}}
AUTH:               ?token=
PERMISSION:         authenticated driver
TABLES:             driver_capability_profiles, dm_vehicles
STATUS TRANSITIONS: none
NOTIFICATION:       none
PAYOUT EFFECT:      none
ACCEPTANCE TEST:    allowed_values.vehicle_types is non-empty and every value
                    is selectable in the app without a client-side list.
```

**Question to resolve:** the platform currently has two vehicle vocabularies.

- Legacy `dm_vehicles` (`GET /api/v1/get-vehicles`) has exactly three rows:
  `bike`, `car`, `Bycycle`. This is what driver **registration** uses.
- The capability module serves its own `allowed_values.vehicle_types`, which
  the app reads without hardcoding, but whose contents are unknown from
  outside (401).

The P0 brief asks the Driver app to support bicycle, car, cargo van, pickup
truck, box truck, medical courier, package-route, dedicated-route and
load-board eligibility. **Only bicycle and car exist in `dm_vehicles`
today.** A driver who owns a cargo van or box truck cannot register one.

Please confirm:

1. Which of the two vocabularies is authoritative for a driver's vehicle.
2. Whether `cargo van`, `pickup truck` and `box truck` should be added to
   `dm_vehicles` (with translations), or whether capability-profile
   supersedes it and registration should switch to that endpoint.
3. Whether medical courier / package route / dedicated route / load board
   eligibility are vehicle types or capability flags. The app models them as
   capability flags (`has_medical_courier_training`, `has_cooler_bag`,
   `has_liftgate`, `available_for_*`), which appears correct — please
   confirm those field names are the ones the backend persists.

Until this is answered the driver login screen advertises workstreams
("Cargo Van & Box Truck") that a driver cannot actually register for. The app
deliberately does not invent the missing types.

---

## CONTRACT-4 — Daily earnings series for the dashboard chart

```
FEATURE:            Weekly earnings breakdown
METHOD:             GET
PATH:               /api/v1/urban-goodz/driver/earnings/daily   (proposed)
REQUEST:            ?from=YYYY-MM-DD&to=YYYY-MM-DD
RESPONSE:           {days: [{date: "YYYY-MM-DD", amount: <decimal>,
                    job_count: <int>}], total: <decimal>}
AUTH:               ?token=
PERMISSION:         authenticated driver
TABLES:             delivery_man_wallets, order_transactions
STATUS TRANSITIONS: none
NOTIFICATION:       none
PAYOUT EFFECT:      reporting only; must reconcile with payout history
ACCEPTANCE TEST:    sum(days[].amount) equals this_week_earning from
                    /api/v1/delivery-man/profile for the same window.
```

**Why:** the dashboard's "Weekly Earnings" chart was fabricated. It fanned
`this_week_earning` across seven fixed multipliers (0.12, 0.15, 0.18, 0.13,
0.20, 0.14, 0.08), so every driver saw the identical invented curve
presented as their own daily history. That has been removed; the card now
shows the real weekly total. The chart returns when this route exists.

---

## CONTRACT-5 — Account state semantics on login

```
FEATURE:            Driver login account states
METHOD:             POST
PATH:               /api/v1/auth/delivery-man/login
REQUEST:            {phone: <phone or email>, password: <string>}
RESPONSE (200):     {token: <string>, ...}  — full shape unconfirmed
RESPONSE (401):     {"errors":[{"code":"auth-001","message":"Incorrect
                    credential  please try again"}]}
RESPONSE (403):     {"errors":[{"code":"<field>","message":"..."}]}
RESPONSE (429):     {"message":"Too Many Attempts."} + retry-after header
AUTH:               none
PERMISSION:         public
TABLES:             delivery_men
STATUS TRANSITIONS: none
NOTIFICATION:       none
PAYOUT EFFECT:      none
ACCEPTANCE TEST:    a pending-approval driver, a rejected driver and a
                    suspended driver each receive a distinct, stable `code`.
```

**Requested:** distinct error codes for the non-credential rejection states —
for example `auth-pending`, `auth-rejected`, `auth-suspended`, `auth-inactive`.

Today the app cannot distinguish "wrong password" from "your application is
still under review" except by the human-readable message, which is not safe
to branch on. It therefore maps `auth-001` to a credentials message and
displays every other server message verbatim rather than inventing wording
for a state it cannot detect. Stable codes would let the app show the right
next step (wait for approval / contact support / re-apply).

Also please confirm whether `delivery_men.status`, `.active` and any
application-state column are returned by `/api/v1/delivery-man/profile`, and
what values mean approved vs pending vs rejected.

---

## CONTRACT-6 — Password reset

```
FEATURE:            Driver password reset
METHOD:             POST
PATH:               /api/v1/auth/delivery-man/forgot-password   (proposed)
REQUEST:            {phone: <phone or email>}
RESPONSE:           {message: <string>}  — always 200, never reveal whether
                    the account exists
AUTH:               none
PERMISSION:         public, rate limited (suggest 3/hour per identifier)
TABLES:             delivery_men, password_resets
STATUS TRANSITIONS: none
NOTIFICATION:       SMS or email with a reset link/code
PAYOUT EFFECT:      none
ACCEPTANCE TEST:    a locked-out driver can regain access without an operator.
```

No reset route exists (405). The app's "Forgot password" dialog previously
collected a phone number, called nothing, and told the driver "Reset Code
Sent" — they would wait indefinitely for a message that was never sent. It
now tells them to contact support. This is a real operational cost until the
route exists.

---

## DEFECT-7 — AI driver endpoints return 500

`GET /api/v1/urban-goodz/cross-app/ai/driver/daily-summary` returns
HTTP 500 `{"message":"Server Error"}` **without authentication**. A route
that 500s before the auth check usually means it throws during boot or
middleware rather than rejecting the anonymous caller — every other
protected route on this backend returns 401 here.

Not a Driver P0 blocker (the AI assistant screen is secondary), but it is a
deployed route in a broken state and worth triaging.

---

## Addendum — how POST routes were verified (2026-07-25)

The `401` vs `405` rule at the top of this file works for GET routes but
**cannot** be used on POST-only routes. This backend has a catch-all
fallback, so a `GET` to a deployed POST route and a `GET` to a URI with no
route at all both return the same `302` redirect to the admin site root.

The discriminator is `OPTIONS`, which Laravel answers with an `Allow`
header listing the verbs actually registered for that URI. It mutates
nothing and needs no token:

| `Allow` header | Meaning |
|---|---|
| `GET,HEAD,POST` | a POST route is deployed at this URI |
| `GET,HEAD` | only the fallback matched — no POST route exists |

Verified deployed this way: `business-jobs/{id}/{accept,start,pickup,
delivery,proof-pickup,proof-delivery,exception}`,
`active-jobs/{id}/{start,complete,cancel,status}`,
`load-board/{id}/{bid,accept}`, `payout-request`.

---

## CONTRACT-8 — Arrival check-in has no route

```
FEATURE:            Driver arrival check-in (at pickup / at dropoff)
METHOD:             POST
PATH:               /api/v1/urban-goodz/driver/business-jobs/{id}/arrived
                    (proposed)
REQUEST:            {latitude: <float>, longitude: <float>,
                     arrived_at: <ISO8601>, leg: "pickup"|"dropoff"}
RESPONSE:           {job: <BusinessJob with status "arrived">}
AUTH:               driver bearer token
PERMISSION:         only the driver the job is assigned to
TABLES:             business_jobs (status), business_job_events
STATUS TRANSITIONS: driver_en_route -> arrived
NOTIFICATION:       notify the business contact that the driver has arrived
PAYOUT EFFECT:      none directly; arrival timestamp is the usual basis for
                    detention/wait-time pay, so recording it now avoids a
                    backfill later
ACCEPTANCE TEST:    a driver en route can check in on arrival, and the
                    business sees the arrival time.
```

Four spellings were probed and all answer `Allow: GET,HEAD` (absent):
`business-jobs/{id}/arrived`, `/arrive`, `/arrival`, `/check-in`. The same
is true of `active-jobs/{id}/arrived`.

`arrived` is a real step in the product flow (discovery -> accept -> en
route -> **arrived** -> picked up -> delivered), so the app models it in
`lib/models/job_lifecycle.dart` as a transition that exists but has no
endpoint. The detail screen shows an explicit "Arrival check-in is not
available yet" note in place of a button while the job is en route. It does
not offer a control that would post nowhere, and it does not silently drop
the step from the flow.

**Until this exists, arrival time is not captured anywhere.** Note that
`business-jobs/{id}/pickup` is reachable directly from `driver_en_route`,
so the flow is not blocked — only the arrival timestamp is lost.

---

## CONTRACT-9 — Which id space accepts work, and where accepted work lands

`active-jobs/{id}/accept` and `job-discovery/{id}/accept` both answer
`Allow: GET,HEAD` — neither exists. The only deployed accept routes are:

* `POST business-jobs/{id}/accept` — for jobs already assigned to the driver
* `POST load-board/{id}/accept` — for loads on the open board

The driver app previously called `acceptLoad(jobId)` from its active-jobs
list, i.e. it sent an **active-job id to a load-board route**. Those are
different id spaces, so the call either 404'd or — worse — hit an unrelated
load with the same numeric id. Accept has been removed from
`ActiveJobsController` entirely and now lives only on
`LoadBoardController`, keyed by a load id taken from the board response.

Please confirm:

1. `load-board/{id}` ids and `active-jobs/{id}` ids are separate sequences
   (the app now assumes they are).
2. Whether `job-discovery` items are accepted via `load-board/{id}/accept`
   using the discovery item's id, or whether discovery is browse-only. The
   discovery screen currently has no accept action because no route for one
   was found.

---

## CONTRACT-10 — `driver_task_status` vocabulary for `active-jobs/{id}/status`

```
FEATURE:            Marketplace job status updates
METHOD:             POST
PATH:               /api/v1/urban-goodz/driver/active-jobs/{id}/status
                    (deployed)
REQUEST:            {driver_task_status: <string>}
RESPONSE:           {job: {... status: <string> ...}}
AUTH:               driver bearer token
PERMISSION:         only the driver the job is assigned to
```

The route is deployed but the accepted values for `driver_task_status` are
undocumented, and there is no `active-jobs/{id}/pickup` route — so this is
the only way to record a pickup on the marketplace path.

The app currently sends `"picked_up"` and treats the request as successful
**only** if the job the server echoes back has status `picked_up`,
`in_transit` or `delivered`. A 2xx that leaves the status unchanged is
reported to the driver as "not confirmed", never as a completed pickup.

Please publish the enum. If `picked_up` is not the accepted spelling, the
app is currently unable to record marketplace pickups — it will say so
rather than claim one, but the step is effectively blocked.

Also please confirm whether the response echoes the **job** (under a `job`
key, as `start` and `complete` do) or a bare status object; the app reads
`body["job"]["status"]` and treats a missing `job` as unconfirmed.

---

## CONTRACT-11 — Where does an accepted load appear?

`POST load-board/{id}/accept` returns a job. The driver app has two job
lists — `GET business-jobs` (what the Active Jobs screen renders) and
`GET active-jobs` — and it is not documented which one the newly accepted
job appears in, or whether it appears in both.

Until this is answered the app tells the driver "Job #N is yours, refresh
your jobs list" rather than naming a specific screen, because naming the
wrong one sends them to an empty list and looks like the accept failed.

Please state the relationship between `business-jobs` and `active-jobs`:
disjoint sets, overlapping, or one a superset of the other.

---

## CONTRACT-12 — Completion is not an earnings receipt

`POST active-jobs/{id}/complete` and `POST business-jobs/{id}/delivery`
both return the job, not an earnings record. The previous build showed
"Great work! Earnings have been added." on completion — an assertion about
the driver's wallet that the response does not support.

That message has been removed; completion now says only that the delivery
is complete, and earnings are shown from `GET earnings` alone.

If completion does credit the driver synchronously, please include the
resulting earnings row (or at least `{amount, currency, earning_id}`) in
the completion response and the app will show it. If crediting is
asynchronous, please say what the expected lag is so the earnings screen
can set the right expectation instead of appearing to have lost the money.
