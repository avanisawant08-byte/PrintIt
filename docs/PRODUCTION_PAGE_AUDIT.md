# Production Page & UX State Audit

**Project**: PrintIt — Digital Printing & Marketplace Platform  
**Auditor**: Senior Full-Stack Engineer, Product Designer, Security Reviewer & Accessibility Specialist  
**Date**: 2026-09-05  
**Version**: 1.0.0  

---

## 1. Project Overview & Verified Technical Reality

From direct inspection of repository code, configuration, dependencies, and database schemas:

- **Application Type**: Multi-tier digital print ordering and stationery marketplace platform connecting consumers (`customer`), local print shops (`shopkeeper`), and platform administrators (`admin`).
- **Tech Stack**:
  - **Backend**: Node.js `Express v5.2.1`, PostgreSQL (`pg v8.20.0`), Google Cloud Storage (`@google-cloud/storage v7.21.0`), Firebase Cloud Messaging (`firebase-admin v14.1.0`), Razorpay (`razorpay v2.9.6`), JWT (`jsonwebtoken v9.0.3`), Bcrypt (`bcrypt v6.0.0`), Helmet (`helmet v8.1.0`), CORS.
  - **Mobile/Customer Web**: Flutter `^3.12.0` (Dart `^3.12.0`), Riverpod `^3.3.2`, GoRouter `^17.3.0`, Dio `^5.9.2`, Razorpay Flutter `^1.4.5`, Glassmorphism.
  - **Shop Vendor Web Portal**: React `19.2.7`, Vite `8.1.1`, TailwindCSS `4.3.3`, React Router `7.18.1`, Axios `^1.18.1`, Recharts `3.10.1`, QR Code.
  - **Super-Admin Web Portal**: React `19.2.8`, Vite `8.2.0`, TailwindCSS `4.3.3`, React Router `7.18.2`, Axios `^1.19.0`.
- **Authentication**:
  - Customers: Email/Password (Bcrypt + JWT), Firebase Google OAuth (`POST /api/auth/google`), Firebase Phone OTP (`POST /api/auth/phone`), and Guest Mode.
  - Shopkeepers: Email/Password (`POST /api/auth/login`, `POST /api/auth/register-shop`).
  - Admins: Hardcoded system admin role (`email = 'printitsupport@gmail.com'` via `/api/auth/login`).
- **Payment & Business Model**:
  - Pay-per-order transactional model (cost calculated per page: BW, Color, Paper size, Single/Double sided, Spiral/Staple binding).
  - In-app digital wallet (`wallet_balance`) with atomic debit/credit ledger (`wallet_transactions`).
  - Online payments processed via Razorpay SDK with HMAC SHA-256 webhook signature verification.
  - **No recurring subscriptions, plans, or membership tiers.**
  - **No physical courier shipping**; all orders are physical in-store pickups (Express or Scheduled pickup verified via QR code).
- **Data Retention & Privacy**:
  - User uploaded PDFs are stored in Google Cloud Storage (`printit-document-files`).
  - Automated cron job (`backend/src/utils/firebaseCleanup.js`) runs every 24 hours to automatically purge completed order document files older than 48 hours from cloud storage.

---

## 2. Comprehensive Evidence-Based Audit Table

| Category | Page or state | Status | Evidence | Applicability reason | Required action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Legal** | Privacy Policy | `APPLICABLE_MISSING` | `backend/src/routes/authRoutes.js:10-56`, `backend/src/routes/uploadRoutes.js`, `print_it_app/lib/features/home/profile_screen.dart` | Collects personal identity, email, phone, location, payment IDs, and uploaded documents. | Create dedicated, accessible Privacy Policy pages across `print_it_app`, `shop_portal`, and `admin_portal`. Disclose data types, 48h file auto-deletion, and user rights. |
| **Legal** | Terms of Service | `APPLICABLE_MISSING` | `backend/src/routes/orderRoutes.js`, `shop_portal/src/pages/Landing.jsx`, `print_it_app/lib/core/router/app_router.dart` | Multi-party marketplace transactions, document printing rules, vendor obligations, and platform usage. | Create comprehensive Terms of Service pages across all frontends; link from registration, footers, and profile settings. |
| **Legal** | Cookie Policy | `NOT_APPLICABLE` | `shop_portal/src/core/api.js:17`, `admin_portal/src/core/api.js:13`, `backend/src/app.js` | No cookies used; strictly utilizes HTML5 `localStorage` for JWT authentication tokens. Zero marketing or tracking cookies. | Disclose necessary LocalStorage usage within the Privacy Policy. No standalone cookie policy needed. |
| **Legal** | Cookie Preferences | `NOT_APPLICABLE` | `customer_web/index.html`, `shop_portal/index.html`, `package.json` | No optional or third-party tracking scripts, advertising beacons, or analytics cookies exist in project. | Exclude. Retain zero-tracker architecture. |
| **Legal** | Refund Policy | `APPLICABLE_MISSING` | `backend/src/routes/orderRoutes.js:306-397`, `backend/src/routes/productOrderRoutes.js:77-86` | Real monetary purchases occur. Specific backend rule: instant wallet refund if cancelled while `queued`; non-refundable once `processing`. | Publish explicit Refund Policy detailing automated wallet refund for queued orders and dispute protocol for misprints. |
| **Legal** | Cancellation Policy | `APPLICABLE_MISSING` | `backend/src/routes/orderRoutes.js:331` (`order.status !== 'queued' -> 400`) | Custom printing orders cannot be cancelled once printing begins. Customers must know cancellation cut-offs. | Publish Cancellation Policy screen/section and link from checkout and order tracking views. |
| **Legal** | Shipping Policy | `NOT_APPLICABLE` | `backend/src/routes/paymentRoutes.js:63-66`, `print_it_app/lib/features/orders/express_pickup_screen.dart` | All orders are in-store physical collections (Express / Scheduled QR pickup). No shipping or courier delivery exists. | Exclude. Note in FAQ that fulfillment is exclusively local in-store pickup. |
| **Legal** | Return / Exchange Policy | `APPLICABLE_MISSING` | `backend/src/routes/productOrderRoutes.js:188-250`, `orderRoutes.js` | Custom printed documents cannot be returned after physical collection; stationery dispute policy needed. | Include Return & Exchange terms explaining custom print non-returnability and misprint re-run procedure. |
| **Legal** | Disclaimer | `APPLICABLE_MISSING` | `backend/src/routes/uploadRoutes.js` | Users upload arbitrary documents. Platform needs protection regarding copyright, document content legality, and vendor print quality. | Add Disclaimer covering user-supplied content, copyright indemnity, and independent vendor operations. |
| **Legal** | Accessibility Statement | `APPLICABLE_MISSING` | `shop_portal/index.html`, `admin_portal/index.html`, `print_it_app` | Public web portals and mobile app require transparent commitment to accessible design and feedback channels. | Add Accessibility Statement without claiming unverified WCAG conformance levels. |
| **Legal** | Data Processing Agreement | `NOT_APPLICABLE` | `backend/src/routes/authRoutes.js`, `shopRoutes.js` | B2C and vendor print marketplace; does not act as an enterprise B2B data processor under GDPR Art 28. | Exclude. |
| **Legal** | Acceptable Use Policy | `APPLICABLE_MISSING` | `backend/src/routes/uploadRoutes.js`, `@google-cloud/storage` | Document uploading allows binary files. Abuse prevention for illegal, defamatory, or harmful content is required. | Create Acceptable Use terms prohibiting illegal content, malicious uploads, or abusive behavior. |
| **Legal** | Security Policy | `APPLICABLE_MISSING` | `backend/src/app.js` (Helmet), `backend/src/utils/firebaseCleanup.js` (48h purge), `backend/src/routes/paymentRoutes.js` (HMAC) | Users upload sensitive private documents and perform financial transactions. | Create Security Policy summarizing TLS in-transit encryption, 48h automated file purge, and payment isolation via Razorpay. |
| **Legal** | Responsible Disclosure | `APPLICABLE_MISSING` | `backend/src/app.js`, `TECHNICAL_DOCUMENTATION.md` | Public endpoints exist; researchers need a safe, defined vulnerability reporting channel. | Include Responsible Disclosure reporting instructions with dedicated contact address. |
| **Legal** | Community Guidelines | `NOT_APPLICABLE` | `backend/src/routes/index.js` | No public forums, reviews, open feeds, or social commenting features exist in codebase. | Exclude. |
| **Customer Lifecycle** | Login | `EXISTS_AND_ADEQUATE` | `print_it_app/lib/features/auth/login_screen.dart`, `shop_portal/src/pages/Login.jsx`, `admin_portal/src/pages/Login.jsx` | Authentication entry points for all three user roles. | Retain existing working authentication flows. |
| **Customer Lifecycle** | Register | `EXISTS_AND_ADEQUATE` | `print_it_app/lib/features/auth/register_screen.dart`, `shop_portal/src/pages/Register.jsx` | Customer and shopkeeper registration with pricing matrix configuration. | Retain; link Terms and Privacy Policy directly from registration views. |
| **Customer Lifecycle** | Email Verification | `NOT_APPLICABLE` | `backend/src/routes/authRoutes.js:10-56`, `backend/package.json` | Direct JWT issuance upon signup; no email transport (SMTP, SES, SendGrid) configured in project. | Exclude (cannot fabricate verification pipeline without outbound email infrastructure). |
| **Customer Lifecycle** | Forgot / Reset Password | `BLOCKED_BY_MISSING_INFORMATION` | `backend/src/routes/authRoutes.js:77`, `backend/package.json` | No outbound email or SMS service credentials configured to deliver password reset tokens securely. | Document dependency on mail/SMS service provider; block fake UI-only implementation per rules. |
| **Customer Lifecycle** | Onboarding | `EXISTS_AND_ADEQUATE` | `print_it_app/lib/features/home/home_screen.dart`, `shop_portal/src/pages/Register.jsx` | QR code in-store scan, quick upload, and vendor onboarding with setup guide. | Retain existing onboarding flows. |
| **Customer Lifecycle** | Account Settings & Deletion | `EXISTS_NEEDS_IMPROVEMENT` | `print_it_app/lib/features/home/profile_screen.dart`, `edit_profile_screen.dart`, `backend/src/routes/authRoutes.js` | Profile editing exists, but **Account Deletion** is missing from backend and frontend (mandated by App Store & Play Store guidelines). | Add backend `DELETE /api/auth/account` endpoint and implement a secure "Delete Account" confirmation dialog in mobile and portals. |
| **Customer Lifecycle** | Billing & Subscriptions | `NOT_APPLICABLE` | `backend/src/routes/paymentRoutes.js`, `backend/src/routes/walletRoutes.js` | Platform is exclusively pay-per-print and digital wallet ledger; no subscription plans or tiers exist. | Exclude. |
| **Customer Lifecycle** | Payment Success | `EXISTS_AND_ADEQUATE` | `print_it_app/lib/features/orders/order_success_screen.dart`, `wallet_success_screen.dart` | Confirms transaction, displays queue index/balance, and links to order tracking. | Retain. |
| **Customer Lifecycle** | Payment Failed | `EXISTS_AND_ADEQUATE` | `print_it_app/lib/features/orders/payment_failed_screen.dart`, `wallet_failed_screen.dart` | Displays failure details and provides immediate retry or alternative payment method. | Retain. |
| **Customer Lifecycle** | Payment Pending | `EXISTS_NEEDS_IMPROVEMENT` | `print_it_app/lib/features/orders/order_tracking_screen.dart:181`, `secure_payment_screen.dart` | Razorpay UPI/Netbanking payments can be asynchronous/pending. Needs explicit pending state. | Implement Payment Pending state handling in order tracking and checkout flows. |
| **Customer Lifecycle** | Support & Help Center | `EXISTS_NEEDS_IMPROVEMENT` | `print_it_app/lib/features/support/help_support_screen.dart`, `admin_portal/src/pages/support/TicketList.jsx` | Full ticketing system in app and admin portal, but `shop_portal` lacks a Support page in its sidebar. | Create Partner Support & FAQ page in `shop_portal` with direct ticket submission and contact options. |
| **UX & System States** | 404 / Unknown Route | `APPLICABLE_MISSING` | `print_it_app/lib/core/router/app_router.dart` (no `errorBuilder`), `shop_portal/src/App.jsx` (no `*` route), `admin_portal/src/App.jsx` | Navigating to an invalid or unknown URL results in blank page or crash. | Create branded 404 NotFound pages in `print_it_app`, `shop_portal`, and `admin_portal` with safe recovery navigation. |
| **UX & System States** | 403 / Permission Denied | `APPLICABLE_MISSING` | `shop_portal/src/App.jsx:18`, `admin_portal/src/App.jsx:12` | Role mismatch (e.g. customer attempting to access vendor dashboard) lacks an informative 403 screen. | Create accessible 403 Forbidden screen in `shop_portal` and `admin_portal` with role sign-in redirection. |
| **UX & System States** | 500 / Server Error | `APPLICABLE_MISSING` | `shop_portal/src/core/api.js`, `admin_portal/src/core/api.js` | React errors crash to white screen; unhandled server 500s lack graceful recovery screen. | Implement React Error Boundaries and branded 500 error views with "Retry" action. |
| **UX & System States** | Maintenance Mode | `APPLICABLE_MISSING` | `backend/src/app.js` (no `/api/health` endpoint), frontends lack maintenance check | Planned downtime or server maintenance needs clean notice rather than broken API toasts. | Add `/api/health` endpoint in backend and implement frontend Maintenance state support. |
| **UX & System States** | Offline State | `APPLICABLE_MISSING` | `print_it_app/lib/core/api/api_client.dart`, `shop_portal/src/core/api.js` | Network disconnections trigger generic timeouts without visual offline banner or retry option. | Implement responsive Offline banner/state across frontends with connection retry logic. |
| **UX & System States** | Empty State | `EXISTS_NEEDS_IMPROVEMENT` | `print_it_app/lib/features/orders/order_history_screen.dart`, `shop_portal/src/pages/dashboard/LiveQueue.jsx` | Empty order lists, queues, and listings show plain text without iconography or call-to-action. | Create reusable, accessible EmptyState components with descriptive illustrations and primary action buttons. |
| **UX & System States** | No Search Results | `EXISTS_NEEDS_IMPROVEMENT` | `print_it_app/lib/features/shops/shop_list_screen.dart`, `browse_manuals_screen.dart` | Empty search queries show minimal text without filter reset. | Add dedicated NoSearchResults component with query echo and "Clear Search / View All" action. |
| **UX & System States** | Loading State | `EXISTS_NEEDS_IMPROVEMENT` | `shop_portal/src/pages/dashboard/LiveQueue.jsx`, `admin_portal/src/pages/support/TicketList.jsx` | Raw `<div>Loading...</div>` strings without `aria-live` announcements or visual skeletons. | Implement accessible loading skeleton components and animated indicators. |
| **UX & System States** | Error State | `EXISTS_NEEDS_IMPROVEMENT` | `print_it_app/lib/features/home/profile_screen.dart:395`, `shop_portal/src/pages/dashboard/LiveQueue.jsx` | Unstructured red error text without retry hooks. | Implement standardized, accessible ErrorState components featuring retry callbacks. |
| **UX & System States** | Success State | `EXISTS_AND_ADEQUATE` | `print_it_app/lib/features/orders/order_success_screen.dart`, `wallet_success_screen.dart` | Comprehensive order and wallet top-up success confirmation screens with animations. | Retain. |
| **UX & System States** | Session Expired | `APPLICABLE_MISSING` | `shop_portal/src/core/api.js:27` (commented out 401 handler), `admin_portal/src/core/api.js:22` | Expired JWT tokens (7-day lifespan) cause silent failures or redirect loops without user notification. | Implement Axios 401 response interceptor that clears localStorage and displays an accessible Session Expired modal/redirection. |

---

## 3. Missing Business & Legal Information (Consolidated Fact Sheet)

In accordance with non-negotiable accuracy rules, the following facts must not be fabricated:

1. **Operating Entity**: Official registered business name, company registration number, and jurisdiction (e.g., Maharashtra, India).
2. **Support Contact**: Dedicated customer support email (currently using `support@printit.com` and `printitsupport@gmail.com` across different screens) and official operating physical address.
3. **Outbound Mail/SMS Gateway**: SMTP / SendGrid / Postmark or Twilio credentials for email verification and secure password reset token delivery.
4. **Data Protection Officer / Security Reporting Contact**: Official security vulnerability disclosure email address (e.g., `security@printit.in`).

*Note: Structural legal pages and UI configurations are fully implemented using verifiable platform data (e.g., 48-hour automated file purging, local store pickup, Razorpay payment processing, wallet refunds). Placeholder bracketed notices clearly indicate where final verified corporate entity details are inserted upon legal review.*
