# Print It — Technical Architecture & API Documentation

This is the comprehensive technical documentation for the **Print It** platform, designed for software engineers, system architects, and developers.

---

## 📋 Table of Contents

1. [System Architecture & Technology Stack](#1-system-architecture--technology-stack)
2. [Monorepo & Sub-system Structure](#2-monorepo--sub-system-structure)
3. [Authentication & Security Architecture](#3-authentication--security-architecture)
4. [Database Schema & Data Dictionary](#4-database-schema--data-dictionary)
5. [Order State Machine & Business Logic](#5-order-state-machine--business-logic)
6. [Complete REST API Specification](#6-complete-rest-api-specification)
7. [Cloud Storage & Background Cron Jobs](#7-cloud-storage--background-cron-jobs)
8. [Real-time Push Notifications & WebSockets](#8-real-time-push-notifications--websockets)
9. [Payment Gateway & In-App Ledger Engine](#9-payment-gateway--in-app-ledger-engine)
10. [Local Development & Deployment Guide](#10-local-development--deployment-guide)

---

## 1. System Architecture & Technology Stack

The platform implements a decoupled multi-tier architecture consisting of a centralized RESTful API gateway, relational database storage, Google Cloud file storage, and three specialized client frontends:

```
                               ┌───────────────────────────────────────────┐
                               │       Google Cloud Storage (GCS)          │
                               │        (PDFs, Document Assets)            │
                               └─────────────────────▲─────────────────────┘
                                                     │ (Signed Uploads/Downloads)
┌─────────────────────────────┐                      │
│     Customer Mobile App     │ ──────────────┐      │
│  (Flutter 3.12, Riverpod,   │               │      │
│   GoRouter, Razorpay SDK)   │               ▼      │
└─────────────────────────────┘     ┌────────────────┴─────────────────────┐       ┌────────────────────────────┐
                                    │          Node.js Express 5           │ ────► │     PostgreSQL Database    │
┌─────────────────────────────┐ ──► │            REST API                  │       │  (Connection Pool, Index)  │
│   Shop Vendor Web Portal    │     │  (JWT, Bcrypt, Helmet, Joi Validator)│ ◄──── │                            │
│  (React 19, Vite, Tailwind) │     └────────────────┬─────────────────────┘       └────────────────────────────┘
└─────────────────────────────┘                      │
                                                     ▼
┌─────────────────────────────┐             ┌──────────────────────────────┐
│    Admin Platform Portal    │             │   Firebase Admin SDK / FCM   │
│  (React 19, Vite, Tailwind) │             │ (Push Notifications Engine)  │
└─────────────────────────────┘             └──────────────────────────────┘
```

### Technology Stack Matrix

| Layer | Component / Package | Version / Description |
| :--- | :--- | :--- |
| **Backend Gateway** | Express.js | `v5.2.1` (Node.js runtime environment) |
| **Database** | PostgreSQL | `pg v8.20.0` connection pool |
| **Object Storage** | Google Cloud Storage | `@google-cloud/storage v7.21.0` |
| **Cache & Cleanup** | Redis & Custom Cron | `ioredis v5.10.1` & automated file cleanup scheduler |
| **Push Engine** | Firebase Admin SDK | `firebase-admin v14.1.0` (FCM) |
| **Payment Gateway** | Razorpay Node SDK | `razorpay v2.9.6` |
| **Auth & Security** | JWT, Bcrypt, Helmet, CORS | `jsonwebtoken v9.0.3`, `bcrypt v6.0.0`, `helmet v8.1.0` |
| **Mobile Client** | Flutter / Dart | `Dart SDK ^3.12.0`, `flutter_riverpod ^3.3.2`, `go_router ^17.3.0` |
| **Web Frontend** | React / Vite / Tailwind | `React v19.2`, `Vite v8.1`, `TailwindCSS v4.3` |

---

## 2. Monorepo & Sub-system Structure

```
print_it/
├── backend/                  # Node.js Express API & Database Services
│   ├── src/
│   │   ├── app.js            # Express application bootstrap & middleware
│   │   ├── config/           # Database pool & environment initialization
│   │   ├── controllers/      # Business logic handlers
│   │   ├── middleware/       # Auth guards, role verification, file uploaders
│   │   ├── routes/           # REST API endpoint route definitions
│   │   └── utils/            # FCM helper, file cleanup, QR generators
│   └── package.json
├── print_it_app/             # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/             # API client (Dio), theme, router, local storage
│   │   ├── features/         # Auth, Home, Shop discovery, Orders, Wallet, Support
│   │   └── main.dart         # Entry point & Riverpod Scope Initialization
│   └── pubspec.yaml
├── shop_portal/              # Shop Owner Vendor Web Application
│   ├── src/
│   │   ├── pages/dashboard/  # LiveQueue, Pricing, MyListings, Orders, Wallet
│   │   └── App.jsx           # React routes & auth context provider
│   └── package.json
└── admin_portal/             # Platform Super-Admin Web Application
    ├── src/
    │   ├── pages/            # PayoutManagement, AddShop, SupportTickets
    │   └── App.jsx           # Admin portal routing
    └── package.json
```

---

## 3. Authentication & Security Architecture

- **Token Standard**: JSON Web Token (JWT) issued upon successful authentication.
- **Header Format**: `Authorization: Bearer <JWT_TOKEN>`
- **Password Hashing**: Bcrypt with salt rounds = 10.
- **Role-Based Access Control (RBAC)**:
  - `customer`: Access to orders, public shop discovery, wallet, support.
  - `shop`: Access to live queue, pricing matrix, shop operational settings, earnings.
  - `admin`: Full access to payout approvals, shop onboarding, and global tickets.
- **Middleware Guards**:
  - `authenticateToken`: Decodes JWT payload and attaches `req.user` or `req.shop_id`.
  - `requireRole(['shop', 'admin'])`: Enforces strict privilege validation.

---

## 4. Database Schema & Data Dictionary

### Table: `users`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `user_id` | `UUID / SERIAL` | `PRIMARY KEY` | Unique user identifier |
| `email` | `VARCHAR(255)` | `UNIQUE, NOT NULL` | User email address |
| `password_hash` | `VARCHAR(255)` | `NULLABLE` (Google OAuth) | Bcrypt encrypted password |
| `full_name` | `VARCHAR(255)` | `NOT NULL` | User full display name |
| `phone` | `VARCHAR(20)` | `NULLABLE` | Contact mobile number |
| `role` | `VARCHAR(20)` | `DEFAULT 'customer'` | Enum: `customer`, `shop`, `admin` |
| `wallet_balance` | `NUMERIC(10, 2)`| `DEFAULT 0.00` | Account digital wallet balance |
| `fcm_token` | `TEXT` | `NULLABLE` | Firebase Cloud Messaging push token |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP`| Account creation timestamp |

### Table: `shops`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `shop_id` | `UUID / SERIAL` | `PRIMARY KEY` | Unique shop identifier |
| `owner_id` | `INT / UUID` | `FOREIGN KEY (users)` | Associated user account |
| `name` | `VARCHAR(255)` | `NOT NULL` | Shop business name |
| `address` | `TEXT` | `NOT NULL` | Physical location address |
| `latitude` | `NUMERIC(10, 8)`| `NULLABLE` | Geolocation latitude |
| `longitude` | `NUMERIC(11, 8)`| `NULLABLE` | Geolocation longitude |
| `is_open` | `BOOLEAN` | `DEFAULT true` | Live operational status toggle |
| `opening_time` | `TIME` | `DEFAULT '09:00'` | Daily opening time |
| `closing_time` | `TIME` | `DEFAULT '21:00'` | Daily closing time |
| `wallet_balance` | `NUMERIC(10, 2)`| `DEFAULT 0.00` | Shop net earnings balance |

### Table: `shop_pricing`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | `PRIMARY KEY` | Unique rule identifier |
| `shop_id` | `FOREIGN KEY` | `REFERENCES shops(shop_id)`| Target shop |
| `color` | `VARCHAR(20)` | `NOT NULL` | Enum: `bw`, `color` |
| `size` | `VARCHAR(10)` | `NOT NULL` | Enum: `A4`, `A3`, `Letter`, `Legal` |
| `sides` | `VARCHAR(20)` | `NOT NULL` | Enum: `single`, `double` |
| `price_per_page` | `NUMERIC(8, 2)` | `NOT NULL` | Unit page cost |
| `binding_staple_price`| `NUMERIC(8, 2)`| `DEFAULT 0.00` | Stapling fee |
| `binding_spiral_price`| `NUMERIC(8, 2)`| `DEFAULT 0.00` | Spiral binding fee |

### Table: `orders`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `order_id` | `UUID / SERIAL` | `PRIMARY KEY` | Unique order identifier |
| `customer_id` | `FOREIGN KEY` | `REFERENCES users(user_id)`| Purchasing user |
| `shop_id` | `FOREIGN KEY` | `REFERENCES shops(shop_id)`| Target print vendor |
| `files` | `JSONB` | `NOT NULL` | Array of file objects `{ url, filename, pages }` |
| `print_options` | `JSONB` | `NOT NULL` | `{ color, size, sides, copies, page_range, binding }` |
| `status` | `VARCHAR(30)` | `DEFAULT 'queued'` | Enum: `queued`, `printing`, `ready`, `completed`, `cancelled` |
| `queue_position`| `INT` | `DEFAULT 1` | Relative queue index |
| `amount_total` | `NUMERIC(10, 2)`| `NOT NULL` | Final calculated order total |
| `payment_status`| `VARCHAR(20)` | `DEFAULT 'pending'` | Enum: `pending`, `paid`, `refunded` |
| `pickup_qr` | `TEXT` | `NULLABLE` | Verification QR code string |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP`| Order placement timestamp |

---

## 5. Order State Machine & Business Logic

```
   ┌──────────┐
   │ CREATED  │ ──(Payment Verified)──► ┌──────────┐
   └──────────┘                         │  QUEUED  │ ──(Shop Accepts)──► ┌───────────┐
        │                               └──────────┘                     │ PRINTING  │
 (Cancel/Fail)                               │                           └─────┬─────┘
        ▼                              (Cancel & Refund)                       │
   ┌──────────┐                              │                         (Print Finished)
   │CANCELLED │ ◄────────────────────────────┴─────────────────────────┐       │
   └──────────┘                                                        │       ▼
                                                                  ┌──────────┐
                                                                  │  READY   │
                                                                  └────┬─────┘
                                                                       │
                                                                 (QR Verified)
                                                                       │
                                                                       ▼
                                                                  ┌──────────┐
                                                                  │COMPLETED │
                                                                  └──────────┘
```

---

## 6. Complete REST API Specification

### Authentication Routes (`/api/auth`)
- `POST /api/auth/register` — Payload: `{ email, password, full_name, phone }` ➔ Returns `{ token, user }`
- `POST /api/auth/login` — Payload: `{ email, password }` ➔ Returns `{ token, user }`
- `POST /api/auth/google` — Payload: `{ idToken }` ➔ Authenticates via Firebase/Google auth.

### Public & Discovery (`/api/public`)
- `GET /api/public/shops?lat=&lng=&search=` — Returns shop list with distance calculation and open status.
- `GET /api/public/shops/:id` — Returns single shop record with capability tags.
- `GET /api/public/shops/:id/pricing` — Returns active pricing matrix rows for price calculation.

### Orders (`/api/orders`)
- `POST /api/orders` — Header: `Bearer <token>` | Payload: `{ shop_id, files, print_options, amount_total }` ➔ Deducts wallet, inserts order in transaction.
- `GET /api/orders/my-orders` — Returns list of orders placed by customer.
- `POST /api/orders/:id/cancel` — Triggers immediate cancellation state and wallet credit transaction.

### Vendor Shop Operations (`/api/shop`)
- `GET /api/shop/live-queue` — Header: `Bearer <token>` ➔ Returns pending orders filtered by status = `queued` or `printing`.
- `PUT /api/shop/orders/:id/status` — Payload: `{ status: 'printing' | 'ready' | 'completed' }` ➔ Updates state & fires FCM message.
- `GET /api/shop/pricing` — Returns shop's active pricing config.
- `POST /api/shop/pricing` — Payload: Array of pricing matrix objects to upsert.
- `PUT /api/shop/status` — Payload: `{ is_open: boolean }` ➔ Toggles public visibility.

### Wallet & Payments (`/api/wallet` & `/api/payments`)
- `GET /api/wallet/balance` — Returns `{ wallet_balance }`.
- `GET /api/wallet/transactions` — Returns last 50 wallet transaction ledger entries.
- `POST /api/payments/create-razorpay-order` — Payload: `{ amount }` ➔ Returns Razorpay order object.
- `POST /api/payments/verify` — Payload: `{ razorpay_order_id, razorpay_payment_id, razorpay_signature }` ➔ Validates HMAC SHA256 signature and credits user wallet.

### Admin Payouts (`/api/admin/payouts`)
- `GET /api/admin/payouts` — Returns list of pending shop payout requests.
- `POST /api/admin/payouts/:id/approve` — Payload: `{ transaction_reference }` ➔ Marks payout completed and updates balances.

---

## 7. Cloud Storage & Background Cron Jobs

- **Google Cloud Storage (GCS)**:
  - Documents uploaded via Multer are streamed to Google Cloud Storage bucket.
  - Generates secure signed URLs with limited expiration time.
- **Automated Cleanup Scheduler (`firebaseCleanup.js`)**:
  - Runs periodic background cleanup job (every 24 hours).
  - Identifies completed print orders older than 48 hours.
  - Automatically deletes underlying document files from GCS to enforce privacy and free storage space.

---

## 8. Real-Time Push Notifications & WebSockets

- **Firebase Cloud Messaging (FCM)**:
  - Mobile client registers device FCM token on startup.
  - Server invokes `firebase-admin.messaging().send()` whenever an order status changes (`Printing`, `Ready for Pickup`).
- **Web App Sound Alerts**:
  - Shop Portal polls or uses SSE/WebSockets to trigger HTML5 Web Audio API chimes upon detection of a new `queued` order.

---

## 9. Payment Gateway & In-App Ledger Engine

### Atomic Wallet Transactions
All wallet modifications use isolated PostgreSQL database transactions (`BEGIN`, `SELECT ... FOR UPDATE`, `UPDATE users SET wallet_balance = wallet_balance + $1`, `INSERT INTO wallet_transactions`, `COMMIT`) to prevent race conditions or double-spending.

```sql
BEGIN;
SELECT wallet_balance FROM users WHERE user_id = $1 FOR UPDATE;
UPDATE users SET wallet_balance = wallet_balance - $2 WHERE user_id = $1;
INSERT INTO wallet_transactions (user_id, amount, type, reference_id) VALUES ($1, $2, 'debit', $3);
COMMIT;
```

---

## 10. Local Development & Deployment Guide

### Environment Setup

Create `.env` file in `backend/`:
```env
PORT=3000
DATABASE_URL=postgres://postgres:password@localhost:5432/printit_db
JWT_SECRET=super_secret_jwt_key_123
GCS_BUCKET_NAME=printit-document-files
GOOGLE_APPLICATION_CREDENTIALS=./gcp-key.json
RAZORPAY_KEY_ID=rzp_test_xxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxx
```

### Running Backend API
```bash
cd backend
npm install
npm run dev
```

### Running Shop Web Portal
```bash
cd shop_portal
npm install
npm run dev
```

### Running Admin Web Portal
```bash
cd admin_portal
npm install
npm run dev
```

### Running Flutter Mobile App
```bash
cd print_it_app
flutter pub get
flutter run
```
