# Urban Goodz Shopper App — Complete Screen and Control Census

## Repository Identity
- **Application**: Urban Goodz Shopper
- **Repository**: UrbanGoodz2026-Revised
- **Path**: `C:\Users\D'Andre Good\Documents\GitHub\UrbanGoodz2026-Revised`
- **Branch**: `customer-tester-build-sprint`
- **Local SHA**: `663f4dba719250e86222578ee22e6b0e6f355a24`
- **Remote SHA**: `663f4dba719250e86222578ee22e6b0e6f355a24`
- **Package ID**: `com.urbangoodz.customer`
- **App Label**: `Urban Goodz Shopper`
- **Pubspec Identity**: `sixam_mart` v3.9.0+5 (Legacy name identified for update)
- **API Base URL**: `https://admin.urbangoodzdelivery.com`
- **Firebase Project**: `urbaneatz` (`709013709032`)
- **Google Services Package**: `com.urbangoodz.customer`

---

## Screen & Control Inventory

### 1. STARTUP AND IDENTITY
- **Splash Screen** (`lib/features/splash/screens/splash_screen.dart`): Checks API config, zone availability, maintenance mode, force update. Status: WIRED.
- **Onboarding Screen** (`lib/features/onboarding/screens/onboarding_screen.dart`): Multi-slide splash walkthrough. Status: WIRED.
- **Permissions Handler** (`lib/helper/permission_helper.dart`): Requests location, notifications, camera. Status: WIRED.
- **Environment & Maintenance** (`lib/features/splash/controllers/splash_controller.dart`): Checks `/api/v1/config`. Status: WIRED.

### 2. AUTHENTICATION
- **Registration** (`lib/features/auth/screens/sign_up_screen.dart`): POST `/api/v1/auth/register`. Status: WIRED.
- **Login / Phone Login** (`lib/features/auth/screens/sign_in_screen.dart`): POST `/api/v1/auth/login`. Status: WIRED.
- **OTP Verification** (`lib/features/auth/screens/verification_screen.dart`): POST `/api/v1/auth/verify-phone`. Status: WIRED (Firebase SMS).
- **Forgot Password / Reset** (`lib/features/auth/screens/forget_pass_screen.dart`): POST `/api/v1/auth/forgot-password`. Status: WIRED.
- **Social Login (Google/Facebook)** (`lib/features/auth/widgets/social_login_widget.dart`): Social token handoff. Status: PARTIAL (Google Active, FB Mock fallback).
- **Logout & Token Expiry** (`lib/features/auth/controllers/auth_controller.dart`): Token removal, API reset. Status: WIRED.

### 3. LOCATION AND MARKET
- **Address Search & Map Selector** (`lib/features/address/screens/add_address_screen.dart`): Zone-aware location picker. Status: WIRED.
- **Houston Live Zone & Zones**: GET `/api/v1/zone/check`. Status: WIRED.

### 4. HOME & DISCOVERY
- **Home Surface** (`lib/features/home/screens/home_screen.dart`): Module dynamic grid, banners, campaigns. Status: WIRED.
- **Ask Urban Goodz / Genie (AI)** (`lib/features/urban_goodz/ai/`): Conversational query dispatcher. Status: PARTIAL (Backend endpoint connected, voice input mock).
- **Black-Owned Spotlight / UG+ Hub**: Featured store query. Status: WIRED.

### 5. MODULES (12 Core Vertical Markets)
1. **Restaurants**: Wired (`/api/v1/stores/get-stores?module_id=1`). Real database items.
2. **Food Trucks**: Wired (`module_id=2`). Real database items.
3. **Grocery/Markets**: Wired (`module_id=3`). Real database items.
4. **Retail/Shopping**: Wired (`module_id=4`). Real database items.
5. **Beauty/Personal Care**: Wired (`module_id=5`). Real database items.
6. **Pharmacy/Health**: Wired (`module_id=6`). Real database items.
7. **Liquor/Beveragez**: Wired (`module_id=7`). Age-verification gate active.
8. **THC/CBD**: Wired (`module_id=8`). Age gate & zone restriction active.
9. **Home-based Businesses**: Wired (`module_id=9`). Merchant identity tag active.
10. **Car Rentals**: Partial (`/api/v1/rental/vehicles`). Vehicle listings wired; booking form partial.
11. **Events/Creators**: Partial (`/api/v1/events`). Flyers wired; ticket QR code pass generation partial.
12. **Courier/Parcel**: Wired (`/api/v1/parcel/category`). Custom parcel flow wired.

### 6. CART, CHECKOUT, AND ORDERS
- **Cart & Store Restrictions** (`lib/features/cart/screens/cart_screen.dart`): Multi-store validation, fee calculation. Status: WIRED.
- **Checkout & Payment** (`lib/features/checkout/screens/checkout_screen.dart`): COD, Digital Payment, Wallet. Status: WIRED.
- **Order Tracking & History** (`lib/features/order/screens/order_tracking_screen.dart`): Live driver tracking map. Status: WIRED.

### 7. SPECIAL SURFACES
- **Order Anywhere**: Form UI wired -> POST `/api/v1/customer/order-anywhere/request`. Status: WIRED.
- **Fashion Fit**: Profile & photo upload -> POST `/api/v1/customer/fashion-fit/measurements`. Status: WIRED.
- **Book Anything / Services**: Service provider search & booking form. Status: PARTIAL.
- **Community Marketplace**: P2P listing creation & search. Status: PLACEHOLDER (Waitlist UI).
- **Reels & Video**: Media player feed & product tag overlay. Status: WIRED.
