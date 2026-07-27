# Urban Goodz Cross-Role End-To-End Trace Matrix

| Lifecycle | Starting Role | Participating Roles | Endpoints Traced | Status Transitions | Payment / Ledger Effect | Final Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Marketplace Order** | Shopper | Shopper -> Vendor -> Driver -> Admin | `/checkout`, `/vendor/orders`, `/delivery-man/accept` | `pending` -> `confirmed` -> `processing` -> `handover` -> `delivered` | Customer Debit, Vendor Credit (Minus Fee), Driver Credit, Platform Margin | **WIRED & TESTED** |
| **Order Anywhere** | Shopper | Shopper -> Admin -> Driver | `/order-anywhere/request`, `/purchase-card/activate` | `requested` -> `quoted` -> `approved` -> `card_issued` -> `purchased` -> `delivered` | Customer Escrow, Virtual Card Authorization, Receipt Reconciliation | **WIRED & TESTED** |
| **Business Courier Route** | Business Client | Admin / Dispatcher -> Driver -> Customer | `/batch-intake`, `/dedicated-routes`, `/scan` | `intake` -> `batched` -> `clustered` -> `sequenced` -> `delivering` -> `completed` | Business Client Invoice, Driver Per-Stop Credit | **WIRED & TESTED** |
| **Medical Courier** | Healthcare Sender | Sender -> Driver -> Recipient | `/medical/chain-of-custody`, `/medical/delivery` | `requested` -> `assigned` -> `picked_up` -> `in_transit` -> `delivered` | Premium Medical Delivery Fee, Compliance Ledger | **WIRED & TESTED** |
| **Logistics Load** | Carrier / Shipper | Shipper -> Dispatcher -> Driver | `/loads`, `/loads/bid`, `/loads/dispatch` | `posted` -> `bidded` -> `dispatched` -> `in_transit` -> `delivered` | Freight Escrow, Carrier Payout, Dispatcher Commission | **WIRED & TESTED** |
| **Fashion Fit** | Shopper | Shopper -> Stylist Vendor | `/fashion/measurements`, `/fashion/bids` | `profile_created` -> `bid_received` -> `accepted` -> `completed` | Service Fee Escrow, Stylist Wallet Payout | **WIRED & TESTED** |
| **Service Booking** | Shopper | Shopper -> Service Provider | `/services/book`, `/services/complete` | `requested` -> `confirmed` -> `in_progress` -> `completed` | Deposit Escrow, Service Payout | **WIRED & TESTED** |
| **Rental** | Shopper | Shopper -> Rental Vendor | `/rental/vehicles`, `/rental/reserve` | `reserved` -> `verified` -> `checked_out` -> `returned` | Security Deposit, Rental Daily Rate Ledger | **WIRED & TESTED** |
| **Creator Commerce** | Creator | Creator -> Shopper -> Vendor | `/reels/feed`, `/reels/checkout` | `content_posted` -> `product_tagged` -> `ordered` | Order Revenue, Creator Commission Credit | **WIRED & TESTED** |
| **Event** | Organizer | Organizer -> Admin -> Shopper | `/events`, `/events/checkout`, `/events/scan` | `created` -> `approved` -> `ticket_issued` -> `scanned` | Ticket Sales Escrow, Gate Verification | **WIRED & TESTED** |
| **Messaging** | Any | Shopper <-> Vendor <-> Driver <-> Admin | `/chat/send`, `/chat/messages` | `sent` -> `delivered` -> `read` | N/A | **WIRED & TESTED** |
