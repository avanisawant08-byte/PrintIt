# Print It — Digital Printing & Marketplace Platform

**Print It** is a digital print ordering and stationery marketplace platform linking customers with local print shops and fulfillment vendors.

---

> [!CAUTION]
> ### 🚨 CRITICAL SECURITY NOTICE: MANDATORY SECRET ROTATION BEFORE DEPLOYMENT
> If any API keys, database connection strings (Supabase PostgreSQL password), Razorpay merchant credentials, Firebase Admin SDK private keys, or JWT secrets were previously committed to Git history, **THEY MUST BE IMMEDIATELY REVOKED AND ROTATED IN YOUR CLOUD PROVIDER CONSOLES PRIOR TO PRODUCTION DEPLOYMENT**.
> 
> Simply removing secrets from current files does not erase them from commit history. Ensure you:
> 1. Rotate your **Supabase Database Password** and update `DATABASE_URL`.
> 2. Regenerate your **Razorpay Key Secret** (`RAZORPAY_KEY_SECRET`) in the Razorpay Dashboard.
> 3. Generate a new **Firebase Service Account Private Key** in Google Cloud Console and revoke old keys.
> 4. Generate a fresh, random 64-character **`JWT_SECRET`**.
> 5. Never commit `.env` or `serviceAccountKey.json` files to source control. Use `.env.example` as a template.

---

## 📚 Project Documentation

The project documentation is split into two dedicated guides depending on your target audience:

1. 🟢 **[Layman & Business User Guide (LAYMAN_DOCUMENTATION.md)](LAYMAN_DOCUMENTATION.md)**
   - Written in simple, non-technical everyday language.
   - Explains what the platform does, who uses it, everyday scenarios (ordering prints, buying stationery), how shop owners manage orders, and how wallet payments and support work.

2. 🔵 **[Technical & Architecture Documentation (TECHNICAL_DOCUMENTATION.md)](TECHNICAL_DOCUMENTATION.md)**
   - Written for developers, architects, and engineering teams.
   - Detailed technical architecture, tech stack matrix (Node.js/Express 5, PostgreSQL, Google Cloud Storage, Firebase FCM, Flutter 3.12, React 19), full database schema & constraints, REST API specifications, payment engine logic, and deployment instructions.

---

## 🛠 Sub-system Overview

- **`backend/`**: Express 5 REST API gateway, PostgreSQL database pool, Google Cloud Storage, Firebase Push Notifications, and Razorpay integration.
- **`print_it_app/`**: Flutter mobile app for customers (Riverpod, GoRouter, Razorpay, PDF tools).
- **`shop_portal/`**: React 19 + Vite 8 web portal for print vendors (Live queue alerts, pricing matrix, shop settings, marketplace products).
- **`admin_portal/`**: React 19 + Vite 8 web portal for platform super-admins (Vendor verification, payout approvals, global support desk).

---

## 🚀 Quick Start Commands

- **Backend**: `cd backend && npm install && npm run dev`
- **Shop Portal**: `cd shop_portal && npm install && npm run dev`
- **Admin Portal**: `cd admin_portal && npm install && npm run dev`
- **Mobile App**: `cd print_it_app && flutter pub get && flutter run`
