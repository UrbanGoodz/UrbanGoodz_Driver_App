# Urban Goodz Mobile API Contract Audit Matrix

| Mobile App | API Method | Path | Auth Type | Response Status | Backend Controller | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Shopper** | GET | `/api/v1/config` | Public | 200 OK | `ConfigController@configuration` | **MATCHED** |
| **Shopper** | POST | `/api/v1/auth/login` | Public | 200 OK | `CustomerAuthController@login` | **MATCHED** |
| **Shopper** | POST | `/api/v1/customer/order/place` | Bearer Token | 200 OK | `OrderController@place_order` | **MATCHED** |
| **Shopper** | POST | `/api/v1/customer/order-anywhere/request` | Bearer Token | 201 Created | `OrderAnywhereController@store` | **MATCHED** |
| **Vendor** | POST | `/api/v1/vendor/auth/login` | Public | 200 OK | `VendorAuthController@login` | **MATCHED** |
| **Vendor** | POST | `/api/v1/vendor/orders/update-status` | Bearer Token | 200 OK | `VendorOrderController@update_status` | **MATCHED** |
| **Driver** | POST | `/api/v1/auth/delivery-man/login` | Public | 200 OK | `DeliveryManLoginController@login` | **MATCHED** |
| **Driver** | POST | `/api/v1/delivery-man/accept-order` | Bearer Token | 200 OK | `DeliveryManOrderController@accept_order` | **MATCHED** |
| **Driver** | POST | `/api/v1/delivery-man/purchase-card/activate` | Bearer Token | 200 OK | `UrbanGoodzDriverPurchaseCardController@activate` | **MATCHED** |
