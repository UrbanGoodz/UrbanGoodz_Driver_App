# Urban Goodz Driver App — Complete Screen and Control Census

## Repository Identity
- **Application**: Urban Goodz Driver
- **Repository**: UrbanGoodz_Vendor_Driver_Sprint (`driver_app`)
- **Path**: `C:\Users\D'Andre Good\Documents\GitHub\UrbanGoodz_Vendor_Driver_Sprint\driver_app`
- **Branch**: `vendor-driver-tester-sprint`
- **Local SHA**: `c633cec1e6389ca9ca3d3d334e9dcbe3e944b27d`
- **Remote SHA**: `c633cec1e6389ca9ca3d3d334e9dcbe3e944b27d`
- **Package ID**: `com.urbangoodz.driver`
- **App Label**: `Urban Goodz Driver`
- **Pubspec Identity**: `urban_goodz_driver` v3.9.1+7
- **API Base URL**: `https://admin.urbangoodzdelivery.com`
- **Firebase Project**: `urbaneatz` (`709013709032`)
- **Google Services Package**: `com.urbangoodz.driver`

---

## Screen & Control Inventory

### 1. STARTUP AND DRIVER AUTHENTICATION
- **Splash & Onboarding** (`lib/screens/splash_screen.dart`, `driver_onboarding_screen.dart`): GPS check, online toggle. Status: WIRED.
- **Driver Login** (`lib/screens/driver_login_screen.dart`): POST `/api/v1/auth/delivery-man/login`. Status: WIRED.
- **Driver Registration** (`lib/screens/driver_registration_screen.dart`): Registration form, vehicle selection, license/insurance upload. Status: WIRED.

### 2. MARKETPLACE DELIVERY & COURIER ROUTES
- **Marketplace Delivery** (`lib/screens/dashboard_screen.dart`): Active job offer popup, accept/reject, turn-by-turn navigation, proof of delivery. Status: WIRED.
- **Dedicated Route Manifest** (`lib/screens/dedicated_route_manifest_screen.dart`): Multi-stop package manifest, barcode scanning, sequence navigation. Status: WIRED.
- **Order Anywhere Purchase Card** (`lib/screens/purchase_card_screen.dart`): One-time virtual card activation, store purchase, receipt photo upload, reconciliation. Status: WIRED.
- **Medical Courier STAT Specimen** (`lib/screens/medical_courier_screen.dart`): Chain of custody verification, temperature log, recipient signature. Status: WIRED.
- **Logistics Load Board** (`lib/screens/load_board_screen.dart`): Heavy load listing, vehicle requirements check, bidding & dispatcher assignment. Status: WIRED.

### 3. DRIVER MONEY & WALLET
- **Earnings & Payouts** (`lib/screens/driver_earnings_screen.dart`): Balance, daily payouts, instant withdrawal. Status: WIRED.
