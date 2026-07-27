# Urban Goodz Shopper App — Legacy Contamination Audit

## Legacy Analysis Summary
- **Total Term Matches**: 5,933 occurrences of legacy strings (`6am`, `6amMart`, `sixam`, `delivery_man`, etc.) across `lib/`.
- **Root Cause**: Base Flutter app was cloned from 6amMart v3.9 template. Modern Urban Goodz features (Fashion Fit, Order Anywhere, Reels, Ask Urban Goodz) were built on top of this foundation.

## Classification Table

| Component / Term | Location | Classification | User-Visible Effect | Remediation Strategy |
| :--- | :--- | :--- | :--- | :--- |
| `sixam_mart` package name | `pubspec.yaml:L1` | **LEGACY DATA** | Hidden (Internal package identifier) | Update to `urban_goodz_shopper` |
| `delivery_man` API paths | `lib/api/api_client.dart` | **REQUIRED 6AM FOUNDATION** | None (Backend alias resolves to `delivery_men`) | Retain API contract compatibility |
| Hardcoded sample items | `lib/features/item/domain/` | **MOCK DATA** | Appears if store load fails | Replace fallback list with dynamic error state |
| Legacy Restaurant terminology | `lib/features/store/` | **CUSTOMIZED URBAN GOODZ FOUNDATION** | Store pages showed "Restaurant" label | Replaced with dynamic `module.unit_type` |
