# vendor_app/ was removed from this repo

This repo contained a stale duplicate of the Urban Goodz **vendor** app.

**Authoritative source:**
`UrbanGoodz_Vendor_App/vendor_app` (package `urban_goodz_vendor`)

## Why it was removed

Three copies of the vendor app existed. This one was the most out of date:

| copy | dart files | newest code |
|---|---|---|
| `UrbanGoodz_Vendor_App/vendor_app` | **56** | 2026-08-13 |
| `claude-order-anywhere-card-driver/vendor_app` | 43 | 2026-08-13 |
| this repo's `vendor_app/` | 36 | 2026-08-03 |

The only signed vendor release APK found on the build machine (2026-09-02)
had been built from *this* copy — 20 dart files behind the real app. Any
testing done against that build was testing stale software.

This copy contained no unique code; it was a strict subset.

**Do not re-add a vendor app here.** The real driver app in this repo is
`driver_app/`. This repo's root is the customer template (`sixam_mart`).
