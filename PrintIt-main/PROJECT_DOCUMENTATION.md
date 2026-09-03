# Print It — Master Technical & Functional Documentation

Welcome to the official master documentation for **Print It**, an all-in-one digital print ordering, live queue management, and stationery marketplace platform.

---

## 📋 Table of Contents

1. [Executive Overview](#1-executive-overview)
2. [Platform Architecture & Technology Stack](#2-platform-architecture--technology-stack)
3. [User Roles & Key Features](#3-user-roles--key-features)
   - [Customer Mobile Application](#customer-mobile-application)
   - [Shop Owner Web Portal](#shop-owner-web-portal)
   - [Platform Admin Web Portal](#platform-admin-web-portal)
4. [Complete Feature Workflows](#4-complete-feature-workflows)
   - [Document Printing Workflow](#document-printing-workflow)
   - [Live Queue & Order Fulfillment Workflow](#live-queue--order-fulfillment-workflow)
   - [Marketplace & Product Ordering Workflow](#marketplace--product-ordering-workflow)
   - [Dynamic Pricing Matrix Setup](#dynamic-pricing-matrix-setup)
   - [Digital Wallet, Payments & Escrow Settlement](#digital-wallet-payments--escrow-settlement)
   - [Support Ticket & Dispute Resolution](#support-ticket--dispute-resolution)
5. [Database Schema & Data Model](#5-database-schema--data-model)
6. [API Endpoint Directory](#6-api-endpoint-directory)
7. [Installation, Setup & Deployment Guide](#7-installation-setup--deployment-guide)

---

## 1. Executive Overview

**Print It** simplifies digital print fulfillment by linking customers directly with local printing vendors and stationery suppliers.

- **Eliminates Long Queues**: Customers customize print settings (color, paper size, page ranges, binding) and pay before arriving.
- **Dynamic Price Engine**: Quotes calculated instantly based on vendor-specific pricing matrices.
- **Live Queue Management**: Real-time status sync between print shops and customer mobile devices.
- **Integrated Marketplace**: Print vendors list and sell stationery, office supplies, and custom merchandise.
- **Unified Financial System**: In-app customer wallets, Razorpay payment gateway integration, automatic vendor balance accounting, and admin payout processing.

---

## 2. Platform Architecture & Technology Stack

The platform consists of five distinct sub-systems:

```
┌───────────────────────────────┐             ┌───────────────────────────────┐
│     CUSTOMER MOBILE APP       │             │     CUSTOMER WEB PORTAL       │
│  (Flutter, Riverpod, FCM)     │             │   (React 19, Vite, Tailwind)  │
└───────────────┬───────────────┘             └───────────────┬───────────────┘
                │                                             │
                ▼                                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             NODE.JS BACKEND API                             │
│       (Express 5, PostgreSQL pool, GCS Storage, Firebase Admin, Redis)       │
└───────────────────────▲─────────────────────────────▲───────────────────────┘
                        │                             │
        ┌───────────────┴─────────────┐         ┌─────┴───────────────────────┐
        │      SHOP OWNER PORTAL      │         │     ADMINISTRATOR PORTAL    │
        │   (React 19, Vite, Tailwind)│         │   (React 19, Vite, Tailwind)│
        └─────────────────────────────┘         └─────────────────────────────┘
```

### Core Technologies

| Sub-system | Technology | Purpose |
| :--- | :--- | :--- |
| **Backend Service** | Node.js (Express 5.x), JavaScript | REST API, Business logic, Authentication, Order state machine |
| **Database** | PostgreSQL (`pg`) | Relational transactional database |
| **Cloud Storage** | Google Cloud Storage (`@google-cloud/storage`) | Secure document & asset storage |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Real-time push updates for order status |
| **Payments** | Razorpay SDK & Internal Wallet Ledger | Online payment processing & balance transfers |
| **Customer App** | Flutter (Dart 3.12), Riverpod | Native cross-platform Android & iOS application |
| **Customer Web Portal** | React 19, Vite, TailwindCSS v4 | Mobile-first web application for customer print ordering |
| **Shop Web Portal** | React 19, Vite 8, TailwindCSS v4 | Vendor queue management, pricing & listings portal |
| **Admin Web Portal** | React 19, Vite 8, TailwindCSS v4 | Platform governance, payout transfers & support desk |

---

## 3. User Roles & Key Features

### Customer Mobile Application (`print_it_app`)

- **User Authentication**:
  - Email & Password sign-up/login.
  - One-tap Google Sign-In authentication.
  - JWT token management and persistence.
- **Shop Discovery**:
  - Location-aware search and shop filtering.
  - View detailed shop cards showing open/closed status, operating hours, and capability tags (Color Printing, Plotting, Hardcover Binding, etc.).
- **Print Job Configurator**:
  - Multi-file document upload (PDF, images).
  - Fine-grained print configuration:
    - **Color Mode**: Black & White / Color.
    - **Paper Size**: A4, A3, Letter, Legal.
    - **Sides**: Single-Sided / Double-Sided (Duplex).
    - **Orientation**: Portrait / Landscape.
    - **Page Ranges**: All pages or custom selection (e.g. `1-4, 7, 10`).
    - **Copies**: Quantity counter.
    - **Binding & Finishing**: None, Staple, Spiral Binding, Softcover.
    - **Fulfillment**: Self-Pickup or Doorstep Delivery.
- **Real-Time Price Estimator**:
  - Live cost breakdown automatically updated as options change.
- **Digital Wallet & Payments**:
  - Razorpay payment gateway integration for instant recharges.
  - In-app wallet ledger for 1-click seamless checkout.
  - Automatic refund processing on order cancellations.
- **Order Tracking & Notifications**:
  - Real-time status progress (`Queued` ➔ `Printing` ➔ `Ready/Out for Delivery` ➔ `Completed`).
  - QR Code generation for contact-free pickup verification.
  - FCM Push Notifications on status updates.
- **Marketplace Shopping**:
  - Product catalog browsing (Stationery, office supplies, printed merchandise).
  - Shopping cart management and product order checkout.
- **Support Center**:
  - Support ticket creation with image attachment.
  - Two-way messaging with support staff.

---

### Shop Owner Web Portal (`shop_portal`)

- **Authentication & Registration**:
  - Vendor sign-up with business registration details.
  - Password management and secure login.
- **Live Queue Dashboard**:
  - Auto-refreshing order list.
  - Audio alert sound on incoming orders.
  - Filter by status (`Queued`, `In-Progress`, `Completed`, `Cancelled`).
  - Print instruction inspector & PDF document preview/download.
  - One-click status updates with automated FCM push notifications sent to customers.
- **Dynamic Pricing Matrix Configurator**:
  - Configure per-page rates based on Color, Paper Size, and Duplexing.
  - Set binding charges (Staple, Spiral, etc.).
- **Shop Settings & Availability**:
  - Instant online/offline toggle switch.
  - Operating hours configuration (Opening time / Closing time).
  - Capability tag selection.
- **Product Listing & Catalog Management**:
  - Add, edit, enable/disable, or delete stationery items.
  - Upload cover photos, price, description, and stock counts.
  - Track product sales orders separately from print orders.
- **Earnings & Financial Wallet**:
  - Real-time revenue analytics dashboard.
  - Track total gross earnings, platform commission deductions, net balance, and available withdrawal balance.
  - Submit payout requests to registered bank/UPI details.

---

### Platform Admin Web Portal (`admin_portal`)

- **Vendor Management**:
  - View all registered print shops.
  - Approve pending vendor applications or suspend shops.
  - Add new shops directly.
- **Financial Payout Operations**:
  - Review all shop withdrawal requests.
  - Verify shop transaction logs & completed order totals.
  - Approve or reject payout transfers with transaction reference IDs.
- **Global Support Desk**:
  - View all support tickets submitted by customers or shop owners.
  - Filter tickets by status (`Open`, `In Progress`, `Resolved`, `Closed`).
  - Send direct responses, resolve disputes, and initiate customer wallet refunds.

---

## 4. Complete Feature Workflows

### Document Printing Workflow

```
[1. Customer Uploads PDF] ──► [2. Selects Print Parameters] ──► [3. Calculates Price]
                                                                        │
[6. Customer Collects / Receives] ◄── [5. Shop Prints File] ◄── [4. Pays via Wallet/Gateway]
```

1. **Upload**: Customer selects one or more PDF files or images in the mobile app.
2. **Configure**: User specifies copies, page ranges, B&W vs Color, paper size, duplexing, and binding choices.
3. **Quotation**: System calculates total price based on the targeted shop's active pricing rules.
4. **Payment**: Customer approves total and pays using Wallet balance or Razorpay.
5. **Queueing**: Order enters shop queue with position index.
6. **Execution & Handover**: Shop accepts order, prints file, updates status, and presents order for QR pickup or delivery.

---

### Live Queue & Order Fulfillment Workflow

1. **Notification**: Shop portal emits an audio chime and displays new order card.
2. **Acceptance**: Vendor clicks "Accept" to move status to `In-Progress`.
3. **Print Execution**: Vendor prints document using exact specified instructions.
4. **Completion Notification**: Shop sets status to `Ready for Pickup`. FCM sends notification to customer app.
5. **QR Code Verification**: Customer arrives at shop, presents pickup QR code. Vendor scans/verifies and marks order `Completed`.

---

### Marketplace & Product Ordering Workflow

1. **Listing**: Vendor adds products (e.g. Notebooks, Pens, Custom Cards) with images and prices.
2. **Discovery & Order**: Customer browses Marketplace tab, selects items, adds to cart, and pays.
3. **Fulfillment**: Shop receives product order notification, packages item, and completes fulfillment.

---

### Dynamic Pricing Matrix Setup

Shops define pricing rules according to the table structure below:

| Color Mode | Paper Size | Print Sides | Price per Page | Staple Price | Spiral Price |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Black & White | A4 | Single-Sided | ₹2.00 | ₹5.00 | ₹30.00 |
| Black & White | A4 | Double-Sided | ₹1.50 | ₹5.00 | ₹30.00 |
| Full Color | A4 | Single-Sided | ₹10.00 | ₹5.00 | ₹30.00 |
| Full Color | A3 | Single-Sided | ₹25.00 | ₹10.00 | ₹50.00 |

---

### Digital Wallet, Payments & Escrow Settlement

1. **Recharge**: User tops up wallet via Razorpay.
2. **Escrow Hold**: Order payment is deducted from user wallet upon placing order.
3. **Completion Credit**: Upon order completion, payment amount (minus platform fee) is credited to vendor's wallet.
4. **Payout**: Vendor requests bank transfer; Admin reviews and approves payout.

---

### Support Ticket & Dispute Resolution

1. **Creation**: User creates ticket under an order with description and images.
2. **Triage**: Support admin reviews ticket in Admin Portal.
3. **Resolution**: Admin communicates via ticket thread, issues wallet refund if justified, and closes ticket.

---

## 5. Database Schema & Data Model

The PostgreSQL database structure consists of the following key tables:

```
┌──────────────┐       ┌──────────────┐       ┌─────────────────┐
│    users     │ ───►  │    shops     │ ───►  │  shop_pricing   │
└──────┬───────┘       └──────┬───────┘       └─────────────────┘
       │                      │
       │                      ▼
       │               ┌──────────────┐       ┌─────────────────┐
       └─────────────► │    orders    │ ───►  │    payments     │
                       └──────────────┘       └─────────────────┘
```

- **`users`**: Stores customer, shop owner, and admin account profiles, password hashes, wallet balances, and FCM push tokens.
- **`shops`**: Stores shop names, addresses, phone, opening/closing hours, online/offline status, and total revenue metrics.
- **`shop_pricing`**: Holds pricing matrix entries linking shop ID to paper size, color, duplexing, and binding prices.
- **`shop_capabilities`**: Stores shop feature tags (e.g. Color Printing, Hardcover, Plotting).
- **`orders`**: Core print order table storing customer ID, shop ID, file storage URLs, print configuration JSON, status enum, total price, and QR code string.
- **`products`**: Marketplace product catalog items listed by shop owners.
- **`product_orders`**: Marketplace product transactions between customers and shop owners.
- **`payments`**: Razorpay transaction logs and status tracking (`created`, `captured`, `failed`).
- **`wallet_transactions`**: Audit log of all wallet credits, debits, refunds, and order deductions.
- **`payout_requests`**: Vendor bank payout requests, requested amounts, status (`pending`, `approved`, `rejected`), and admin notes.
- **`support_tickets` & `ticket_messages`**: Customer service tickets and message history.

---

## 6. API Endpoint Directory

### Base URL: `/api`

#### Authentication (`/auth`)
- `POST /auth/register` — Register a new customer account
- `POST /auth/login` — Customer/Shop/Admin login
- `POST /auth/google` — Google OAuth authentication
- `GET /auth/me` — Fetch current authenticated user profile

#### Public & Shop Discovery (`/public`)
- `GET /public/shops` — List active shops with search & location filters
- `GET /public/shops/:id` — Fetch detailed shop profile & capabilities
- `GET /public/shops/:id/pricing` — Retrieve shop pricing matrix

#### Print Orders (`/orders`)
- `POST /orders` — Create new print order
- `GET /orders/my-orders` — List customer print order history
- `GET /orders/:id` — Get detailed order info and status
- `POST /orders/:id/cancel` — Cancel order & trigger wallet refund

#### Shop Operations (`/shop`)
- `GET /shop/live-queue` — Get pending and active print jobs for vendor
- `PUT /shop/orders/:id/status` — Update order status (`queued`, `printing`, `ready`, `completed`)
- `GET /shop/pricing` — Fetch shop pricing rules
- `POST /shop/pricing` — Update or add pricing rules
- `PUT /shop/status` — Toggle shop open/closed availability
- `GET /shop/analytics` — View revenue & order analytics

#### Wallet & Payments (`/wallet` & `/payments`)
- `GET /wallet/balance` — Check customer wallet balance
- `GET /wallet/transactions` — View wallet ledger history
- `POST /payments/create-razorpay-order` — Initialize Razorpay checkout
- `POST /payments/verify` — Verify signature and credit wallet

#### Products & Marketplace (`/products` & `/product-orders`)
- `GET /products` — Browse marketplace items
- `POST /products` — Add product (Shop owner)
- `POST /product-orders` — Place marketplace order

#### Admin Operations (`/admin/payouts`)
- `GET /admin/payouts` — List all shop payout requests
- `POST /admin/payouts/:id/approve` — Approve payout transfer
- `POST /admin/payouts/:id/reject` — Reject payout request

#### Support Desk (`/support`)
- `POST /support/tickets` — Create support ticket
- `GET /support/tickets` — List user or shop support tickets
- `POST /support/tickets/:id/messages` — Send message in support ticket thread

---

## 7. Installation, Setup & Deployment Guide

### Prerequisites
- Node.js (v18 or higher)
- PostgreSQL (v14 or higher)
- Flutter SDK (v3.12 or higher)
- Google Cloud Project with Cloud Storage Bucket
- Firebase Project (for FCM Notifications & Auth)
- Razorpay Merchant Account

---

### Backend Service Setup (`/backend`)

1. **Navigate to directory**:
   ```bash
   cd backend
   ```
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Environment Configuration**:
   Create a `.env` file in `backend/`:
   ```env
   PORT=3000
   DATABASE_URL=postgresql://username:password@localhost:5432/printit_db
   JWT_SECRET=your_jwt_secret_key
   GCS_BUCKET_NAME=your_gcs_bucket_name
   GOOGLE_APPLICATION_CREDENTIALS=path/to/gcp-key.json
   RAZORPAY_KEY_ID=your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_key_secret
   FIREBASE_SERVICE_ACCOUNT=path/to/firebase-key.json
   ```
4. **Start Development Server**:
   ```bash
   npm run dev
   ```

---

### Shop Portal Setup (`/shop_portal`)

1. **Navigate & Install**:
   ```bash
   cd shop_portal
   npm install
   ```
2. **Launch Portal**:
   ```bash
   npm run dev
   ```
   *Access dashboard at `http://localhost:5173`*

---

### Admin Portal Setup (`/admin_portal`)

1. **Navigate & Install**:
   ```bash
   cd admin_portal
   npm install
   ```
2. **Launch Portal**:
   ```bash
   npm run dev
   ```
   *Access admin panel at `http://localhost:5174`*

---

### Customer Mobile Application Setup (`/print_it_app`)

1. **Navigate to Flutter app**:
   ```bash
   cd print_it_app
   ```
2. **Get Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run Application**:
   ```bash
   flutter run
   ```

---

## 📄 License & Summary

**Print It** is built to deliver an end-to-end modern digital print ecosystem. For technical inquiries, bug reports, or feature requests, submit a support ticket via the Admin Portal or app support desk.
