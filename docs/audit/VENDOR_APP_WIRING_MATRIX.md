# Urban Goodz Vendor App — Wiring Matrix

| Feature / Screen | Component Path | Backend Endpoint | Database Tables | Status | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Vendor Login** | `VendorAuthController` | `POST /api/v1/vendor/auth/login` | `vendors`, `stores` | **WIRED** | Validates store active status |
| **Registration** | `VendorRegisterController` | `POST /api/v1/vendor/auth/register` | `vendors`, `stores`, `store_wallets` | **WIRED** | Pending admin approval pipeline |
| **Dashboard Metrics** | `VendorDashboardController` | `GET /api/v1/vendor/dashboard` | `orders`, `order_details` | **WIRED** | Sales, orders, earnings summary |
| **Product List** | `VendorProductController` | `GET /api/v1/vendor/items` | `items` | **WIRED** | Store-scoped item querying |
| **Add Product** | `VendorProductController` | `POST /api/v1/vendor/items/store` | `items`, `item_campaigns` | **WIRED** | Image & variant upload |
| **Order Processing** | `VendorOrderController` | `POST /api/v1/vendor/orders/update-status` | `orders`, `order_status_logs` | **WIRED** | Triggers driver dispatch notification |
| **Withdrawal Request** | `VendorWalletController` | `POST /api/v1/vendor/wallet/withdraw` | `withdraw_requests`, `store_wallets` | **WIRED** | Ledger balance verification |
