# Urban Goodz Shopper App — Wiring Matrix

| Feature / Screen | Component Path | Backend Endpoint | Database Tables | Status | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Startup / Config** | `SplashController` | `GET /api/v1/config` | `business_settings`, `zones` | **WIRED** | Loads dynamic config & zone rules |
| **User Login** | `AuthController` | `POST /api/v1/auth/login` | `users`, `oauth_access_tokens` | **WIRED** | Passport Bearer token returned |
| **User Register** | `AuthController` | `POST /api/v1/auth/register` | `users` | **WIRED** | Account creation & wallet initialization |
| **Address Picker** | `AddressController` | `POST /api/v1/customer/address/add` | `customer_addresses` | **WIRED** | Geocoding & zone check |
| **Home Modules** | `ModuleController` | `GET /api/v1/modules` | `modules` | **WIRED** | Filters active Houston vertical markets |
| **Store Details** | `StoreController` | `GET /api/v1/stores/details/{id}` | `stores`, `items` | **WIRED** | Real store inventory & schedules |
| **Product Details** | `ItemController` | `GET /api/v1/items/details/{id}` | `items`, `item_campaigns` | **WIRED** | Variants, add-ons, pricing |
| **Cart Operations** | `CartController` | Local + `POST /api/v1/customer/cart` | Local storage / `carts` | **WIRED** | Store isolation enforced |
| **Order Checkout** | `CheckoutController` | `POST /api/v1/customer/order/place` | `orders`, `order_details`, `ledgers` | **WIRED** | Fees, taxes, tip, COD / Digital |
| **Order Anywhere** | `OrderAnywhereController` | `POST /api/v1/customer/order-anywhere` | `order_anywhere_requests` | **WIRED** | Photo upload & admin quote pipeline |
| **Fashion Fit** | `FashionFitController` | `POST /api/v1/fashion/measurements` | `fashion_fit_profiles` | **WIRED** | Silhouette guide & image submission |
| **Reels / Video** | `ReelsController` | `GET /api/v1/reels/feed` | `reels`, `items` | **WIRED** | Video streaming & product tag linkage |
| **Community Marketplace** | `MarketplaceWidget` | N/A (UI Only) | None | **PLACEHOLDER** | UI preview state, needs backend API |
