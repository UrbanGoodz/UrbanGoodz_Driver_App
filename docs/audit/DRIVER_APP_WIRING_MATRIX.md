# Urban Goodz Driver App — Wiring Matrix

| Feature / Screen | Component Path | Backend Endpoint | Database Tables | Status | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Driver Login** | `DriverAuthController` | `POST /api/v1/auth/delivery-man/login` | `delivery_men` | **WIRED** | Passport Bearer token returned |
| **Location Update** | `DriverLocationService` | `POST /api/v1/delivery-man/update-location` | `delivery_men`, `delivery_history` | **WIRED** | Realtime GPS tracking |
| **Accept Delivery** | `DriverOrderController` | `POST /api/v1/delivery-man/accept-order` | `orders` | **WIRED** | Driver assignment & customer push |
| **Proof of Delivery** | `DriverOrderController` | `POST /api/v1/delivery-man/complete-order` | `orders`, `order_details`, `ledgers` | **WIRED** | Photo upload, signature, OTP verify |
| **Route Manifest** | `RouteDetailsController` | `GET /api/v1/delivery-man/dedicated-routes/{id}` | `urban_goodz_dedicated_routes`, `urban_goodz_batch_packages` | **WIRED** | Multi-stop manifest & scan audit |
| **Purchase Card** | `DriverPurchaseCardController` | `POST /api/v1/delivery-man/purchase-card/activate` | `urban_goodz_purchase_cards` | **WIRED** | Spending limit validation |
| **Medical Courier** | `MedicalCourierController` | `POST /api/v1/delivery-man/medical/chain-of-custody` | `medical_courier_jobs` | **WIRED** | STAT specimen tracking |
| **Load Board Bid** | `LoadBoardController` | `POST /api/v1/delivery-man/loads/bid` | `load_board_bids` | **WIRED** | Vehicle class validation |
