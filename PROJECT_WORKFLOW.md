# Print It Platform — End-to-End Operational Workflow

## 1. Executive Summary

**Print It** is an integrated digital print ordering and marketplace platform. It seamlessly connects customers who need print services or office/stationery products with local print shops and fulfillment vendors, backed by centralized platform administration. 

The ecosystem eliminates physical queues at print shops, provides instant cost estimation before placing orders, enables real-time status tracking, and offers seamless payment and payout management for print vendors.

---

## 2. Key Stakeholders & Platforms

```
┌─────────────────────────┐       ┌─────────────────────────┐       ┌─────────────────────────┐
│     Customer (App)      │  ◄──► │    Shop Owner (Web)     │  ◄──► │  Platform Admin (Web)   │
│  • Document Printing    │       │  • Live Print Queue     │       │  • Vendor Verification  │
│  • Custom Configurator  │       │  • Order Fulfillment    │       │  • Payout Approvals     │
│  • Marketplace Shopping │       │  • Pricing & Catalog    │       │  • Customer Support     │
│  • Digital Wallet       │       │  • Earnings & Withdraw  │       │  • System Monitoring    │
└─────────────────────────┘       └─────────────────────────┘       └─────────────────────────┘
```

1. **Customers (App Users)**: Browse nearby print shops, upload files, configure print specifications, order stationery/products, pay via digital wallet or online options, and track orders.
2. **Shop Owners (Print Vendors)**: Manage live print queues, process document print jobs, list stationery/merchandise in the marketplace, configure custom page prices, and request earnings payouts.
3. **Platform Administrators**: Supervise vendor onboarding, review and approve payout transfers, manage platform fees, and handle customer support tickets.

---

## 3. End-to-End Operational Workflows

### Workflow 1: Custom Document Printing Journey (Customer to Shop)

This is the primary workflow for users ordering physical prints of digital documents (PDFs, images, reports, etc.).

```
[Customer Selects Shop] ──► [Uploads Document] ──► [Configures Print Settings]
                                                            │
[Order Picked Up/Delivered] ◄── [Shop Prints Job] ◄── [Payment & Order Placed]
```

1. **Shop Discovery**:
   - Customer opens the mobile app and browses print shops sorted by location, rating, or search query.
   - Customer views shop profile, business hours, available paper types, finishing options, and current operating status (Open/Closed).

2. **File Upload & Print Configuration**:
   - Customer uploads the document file(s).
   - Customer customizes print options:
     - **Color Mode**: Black & White vs. Full Color
     - **Paper Size**: A4, A3, Letter, Legal, etc.
     - **Paper Type / Thickness**: Standard, Premium, Photo Paper, Glossy, etc.
     - **Print Sides**: Single-Sided vs. Double-Sided (Duplex)
     - **Orientation**: Portrait vs. Landscape
     - **Page Selection**: All pages or specific custom ranges (e.g., Pages 1-5, 8)
     - **Copies**: Quantity required
     - **Finishing & Binding**: Spiral binding, soft cover, stapling, laminating, or none
     - **Fulfillment Method**: Self-Pickup at store OR Doorstep Delivery

3. **Dynamic Price Calculation & Checkout**:
   - System instantly calculates the total cost based on the shop's active pricing matrix and selected options.
   - Customer reviews order breakdown (Print cost + Binding cost + Delivery fee if applicable).
   - Customer completes payment using their **In-App Wallet** or instant payment gateway.

4. **Order Confirmation & Real-Time Tracking**:
   - Once payment is confirmed, the order enters the selected shop's **Live Queue**.
   - Customer receives push notifications as the order progresses through stages:
     `Received` ➔ `Printing In-Progress` ➔ `Ready for Pickup / Out for Delivery` ➔ `Completed`.

---

### Workflow 2: Shop Live Queue & Order Processing

This workflow describes how print vendors receive, prioritize, and fulfill print jobs.

1. **New Order Alert**:
   - Shop receives audio/visual alerts on their Live Queue dashboard when a new order arrives.
   - Order details display: Customer Name, Document File preview, Exact Print Specifications, Delivery/Pickup preference, and Deadline.

2. **Order Accept & Print Execution**:
   - Shop accepts the order and downloads/views the print file directly.
   - Shop updates status to **Printing In-Progress**.
   - Vendor prints and binds the document according to the customer's specified parameters.

3. **Fulfillment & Handover**:
   - For **Self-Pickup**: Shop marks order as **Ready for Pickup**. Customer visits shop, presents order verification code, and collects the order.
   - For **Delivery**: Shop assigns a delivery partner or marks **Out for Delivery**.
   - Once handed over, the shop marks the order as **Completed**. Earnings are credited to the shop's platform account balance.

---

### Workflow 3: Marketplace & Products Shopping

Apart from custom print jobs, print shops can sell ready-made items (stationery, notebooks, office supplies, customized merchandise, printed art).

1. **Product Cataloging (Shop Side)**:
   - Shop lists products with images, descriptions, categories, stock inventory, and price.

2. **Browsing & Purchasing (Customer Side)**:
   - Customer navigates to the Marketplace tab in the app.
   - Customer adds items to cart from one or multiple shops.
   - Customer checks out and completes payment.

3. **Product Fulfillment**:
   - Shop receives product order notification.
   - Shop packages the product and dispatches it or keeps it ready for pickup.

---

### Workflow 4: Shop Onboarding & Pricing Matrix Setup

To maintain quality and fair pricing, shop registration and setup follow a structured process.

1. **Registration & Verification**:
   - Vendor registers via the Shop Portal with business details, address, operating hours, and identification.
   - Admin reviews vendor details and approves the shop for public listing.

2. **Pricing Matrix Setup**:
   - Shop configures per-page rates based on paper size, color/B&W, double-sided discounts, and paper quality.
   - Shop defines finishing/binding service fees.
   - Shop sets operational parameters (Minimum order amount, daily capacity, operating hours, online status toggle).

---

### Workflow 5: Digital Wallet, Payments & Earnings Settlement

```
[Customer Recharges Wallet] ──► [Customer Pays for Order] ──► [Funds Held in Escrow]
                                                                        │
[Admin Approves Request] ◄── [Shop Requests Payout] ◄── [Order Completed / Credited]
```

1. **Customer Wallet**:
   - Customers can add funds to their in-app wallet for frictionless 1-click order placements.
   - Instant refund mechanism: If an order is canceled or rejected by a shop, funds instantly return to the customer's wallet.

2. **Shop Earnings Accumulation**:
   - When an order is completed, the payment (minus platform commission fee) is credited to the shop's wallet balance.
   - Shop dashboard displays real-time statistics: Total Revenue, Pending Balance, Withdrawn Amount, and Order Counts.

3. **Payout Requests & Financial Settlement**:
   - Shop submits a **Payout Request** when reaching the minimum withdrawal threshold.
   - Platform Admin reviews payout requests, verifies completed transaction records, and approves bank/UPI transfer.
   - Shop receives payout status update with confirmation transaction reference.

---

### Workflow 6: Customer Support & Dispute Resolution

1. **Ticket Creation**:
   - If a customer or shop owner encounters an issue (e.g., misprint, payment deduction failure, delay, damaged item), they open a **Support Ticket** in their app or portal.
   - User attaches ticket subject, description, order ID, and photos/proof.

2. **Admin Intervention & Resolution**:
   - Support Admin views ticket queue, categorizes priority, and reviews context.
   - Admin can initiate direct messaging with the user/shop, issue refunds to customer wallet, or close resolved tickets.

---

## 4. Lifecycle of a Print Order

Below is the state progression of every print order through the system:

```
┌──────────────┐      ┌──────────────┐      ┌──────────────────┐
│   CREATED    │ ───► │    PAID      │ ───► │ IN LIVE QUEUE    │
└──────────────┘      └──────────────┘      └──────────────────┘
                                                     │
┌──────────────┐      ┌──────────────┐               ▼
│  COMPLETED   │ ◄─── │ READY/OUT    │ ◄─── │ PRINTING STARTED │
└──────────────┘      └──────────────┘      └──────────────────┘
```

- **Created**: Customer has configured print settings but not yet finalized payment.
- **Paid**: Payment verified; sent to target print shop.
- **In Live Queue**: Shop received alert and placed job in processing queue.
- **Printing Started**: Paper & binding preparation under way.
- **Ready for Pickup / Out for Delivery**: Job finalized and waiting for customer collection or dispatch.
- **Completed**: Order handed over; customer confirmed receipt; shop wallet credited.
- **Cancelled / Refunded** *(Exception path)*: Cancelled prior to printing; funds returned to customer wallet.

---

## 5. Key System Benefits

- **Zero Wait Time**: Customers no longer stand in long shop queues or wait around for manual file transfers (USB drives/emails).
- **Transparent Pricing**: Complete cost visibility before making any payment.
- **Queue Efficiency for Print Vendors**: Shops receive pre-configured, print-ready files with exact preferences, eliminating back-and-forth communication.
- **Automated Financial Tracking**: Clear records of earnings, commission platform fees, and seamless bank payouts.
