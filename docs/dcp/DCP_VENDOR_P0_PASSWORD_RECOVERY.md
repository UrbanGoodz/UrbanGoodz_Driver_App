# DCP — Vendor P0: Password Recovery

**Repository:** `UrbanGoodz2026-Revised` (monorepo; `Vendor_Driver_Sprint` is a
linked worktree of it — verified via `git rev-parse --git-common-dir`)
**Worktree:** `C:\Users\D'Andre Good\Documents\GitHub\UrbanGoodz_Vendor_P0_Recovery`
**Branch:** `claude-vendor-p0-recovery`
**Starting SHA:** `2da04816af302869ec36e865b1b02e35f5874529`
**Deployed:** NO

## Identity verification

`vendor_app` tree hash `e8a86a7036d09aae54ec5acd5c80980167b487a9` is identical
across this branch's HEAD, `c633cec`, and `vendor-driver-tester-sprint`. The
branch contains the real Vendor application. `UrbanGoodz2026-Revised` is the
remote repository **name**, not a wrong repo.

## Files changed

| File | Change |
|---|---|
| `vendor_app/lib/repositories/vendor_repository.dart` | +3 methods, contract documented inline |
| `vendor_app/lib/controllers/vendor_password_reset_controller.dart` | NEW — GetX state machine |
| `vendor_app/lib/screens/vendor_password_reset_screen.dart` | NEW — 4-stage flow |
| `vendor_app/lib/screens/vendor_onboarding_screen.dart` | fake reset dialog removed; **fake login fixed** |
| `vendor_app/test/vendor_password_reset_test.dart` | NEW — 17 focused tests |
| `docs/audit/VENDOR_P0_VERIFIED_CENSUS.md` | corrected |

## Endpoint contracts (read from `VendorPasswordResetController.php`)

```
POST auth/vendor/forgot-password  {email}
     200 {message} | 404 {errors:[{code:'not-found'}]} | 403 validation/mail-fail
POST auth/vendor/verify-token     {email, reset_token}
     200 | 400 {code:'reset_token'} | 405 {code:'otp_block_time'|'otp_temp_blocked'} | 403
PUT  auth/vendor/reset-password   {email, reset_token, password, confirm_password}
     200 | 400 {code:'invalid'} | 401 {code:'mismatch'} | 403 password rules
```

Password rule mirrored client-side: min 8, mixed case, letters, numbers,
symbols. `uncompromised()` cannot run on device — server response rendered
verbatim. Throttle: 5 attempts / 60 s, 600 s temp block. Resend = re-POST
forgot-password (no dedicated endpoint). **No expiry check on submit.**

## Test status — separated honestly

- **SOURCE IMPLEMENTED:** yes
- **STATIC ANALYSIS:** `flutter analyze` on all 4 changed files — **No issues found**
- **WIDGET TESTED:** NO
- **UNIT TESTS EXECUTED:** NO — blocked, see below
- **API CONTRACT VERIFIED:** yes, by reading the backend controller
- **LIVE RESET NOT EXECUTED:** correct — no staging vendor fixture

### Blocker: `flutter test` cannot run under this username

Flutter's generated test listener embeds the absolute path into a
single-quoted Dart string. The apostrophe in `C:\Users\D'Andre Good\`
terminates that string, producing a compile error before any test runs:

```
listener.dart:13: Error: 'vendor_app' is already declared in this scope.
const packageConfigLocation = 'file:///C:/Users/D'Andre%20Good/...';
```

Affects **any** Flutter test in this user directory, not this suite. A
directory junction at `C:\UGV` did not help — Flutter resolves it to the real
path first. A true copy at an apostrophe-free path was not attempted: free
disk is **4.0 GB** (below the 15 GB bar), and the existing `C:\UG\*_RC3_Test`
worktrees suggest this workaround is already established practice.

The 17 tests are committed and will run unchanged from a path without an
apostrophe. Their pass state is **unknown and not claimed**.

## Blockers

1. `flutter test` path-apostrophe defect (above).
2. Free disk 4.0 GB — no APK build.
3. No staging vendor fixture — live reset unexecuted.
4. **Phone-OTP login is still a mock** and no backend contract exists for it.
5. Backend discloses account existence on all three reset endpoints.

## Next task

P0, in order: registration/approval-state handling; complete order status
lifecycle; push receipt + order alerts; wallet/withdrawal visibility.
Blocked pending contracts: rental-provider, event-organizer, vendor phone-OTP.

## Continuation command

```
cd "C:\Users\D'Andre Good\Documents\GitHub\UrbanGoodz_Vendor_P0_Recovery"
git log --oneline -3
# to run tests, copy vendor_app to an apostrophe-free path first, e.g. C:\UG\
```
