# Urban Goodz Vendor App — Complete Screen and Control Census

## Repository Identity
- **Application**: Urban Goodz Vendor
- **Repository**: UrbanGoodz_Vendor_Driver_Sprint (`vendor_app`)
- **Path**: `C:\Users\D'Andre Good\Documents\GitHub\UrbanGoodz_Vendor_Driver_Sprint\vendor_app`
- **Branch**: `vendor-driver-tester-sprint`
- **Local SHA**: `c633cec1e6389ca9ca3d3d334e9dcbe3e944b27d`
- **Remote SHA**: `c633cec1e6389ca9ca3d3d334e9dcbe3e944b27d`
- **Package ID**: `com.urbangoodz.vendor`
- **App Label**: `Urban Goodz Vendor`
- **Pubspec Identity**: `urban_goodz_vendor` v3.9.3+10
- **API Base URL**: `https://admin.urbangoodzdelivery.com/api/v1`
- **Firebase Project**: `urbaneatz` (`709013709032`)
- **Google Services Package**: `com.urbangoodz.vendor`

---

## Screen & Control Inventory

### 1. STARTUP AND AUTHENTICATION
- **Splash & Onboarding** (`lib/screens/splash_screen.dart`, `vendor_onboarding_screen.dart`): Config check & vendor state validation. Status: WIRED.
- **Vendor Login** (`lib/screens/vendor_login_screen.dart`): POST `/api/v1/vendor/auth/login`. Status: WIRED.
- **Vendor Registration** (`lib/screens/vendor_registration_screen.dart`): POST `/api/v1/vendor/auth/register`. Business details, zone, module selection, documents upload. Status: WIRED.

### 2. DASHBOARD AND STORE MANAGEMENT
- **Dashboard** (`lib/screens/vendor_dashboard_screen.dart`): Realtime order alerts, revenue metrics, store open/closed toggle. Status: WIRED.
- **Store Profile** (`lib/screens/store_profile_screen.dart`): Address, map pin, cover image, logo, schedule. Status: WIRED.
- **Product Management** (`lib/screens/product_list_screen.dart`, `add_product_screen.dart`): CRUD products, variants, add-ons, pricing. Status: WIRED.

### 3. ORDER HANDLING & WALLET
- **Order List & Detail** (`lib/screens/vendor_orders_screen.dart`): Accept, prepare, mark ready, handed off to driver. Status: WIRED.
- **Wallet & Withdrawal** (`lib/screens/vendor_wallet_screen.dart`): Balance display, request withdrawal. Status: WIRED.
