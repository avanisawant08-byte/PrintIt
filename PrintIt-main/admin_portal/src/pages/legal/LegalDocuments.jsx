import React from 'react';

const LegalDocuments = () => {
  return (
    <div className="p-6 md:p-10 space-y-8 max-w-5xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-on-surface">Platform Compliance & Legal Documents</h1>
        <p className="text-sm text-on-surface-variant mt-1">
          Review live platform legal disclosures, automated privacy protocols, and regulatory dispute standards.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Card 1: Privacy & Data Lifecycle */}
        <div className="p-6 rounded-2xl bg-surface-container border border-outline-variant/30 space-y-3">
          <div className="flex items-center gap-3 text-primary">
            <span className="material-symbols-outlined text-2xl">policy</span>
            <h2 className="text-lg font-bold">Privacy & Document Purge</h2>
          </div>
          <p className="text-xs text-on-surface-variant leading-relaxed">
            Automated cron job runs every 24 hours to delete completed order files older than 48 hours from Google Cloud Storage. LocalStorage is strictly used for JWT tokens; zero tracking cookies.
          </p>
          <div className="pt-2 text-xs font-mono text-primary">
            Status: Active Automated Cron Job (firebaseCleanup.js)
          </div>
        </div>

        {/* Card 2: Refund & Cancellation State Machine */}
        <div className="p-6 rounded-2xl bg-surface-container border border-outline-variant/30 space-y-3">
          <div className="flex items-center gap-3 text-primary">
            <span className="material-symbols-outlined text-2xl">currency_exchange</span>
            <h2 className="text-lg font-bold">Refund & Cancellation Rules</h2>
          </div>
          <p className="text-xs text-on-surface-variant leading-relaxed">
            Orders in <code>queued</code> status qualify for 100% automated instant wallet credit refund upon cancellation. Orders in <code>processing</code> or <code>ready</code> cannot be cancelled due to custom paper consumption.
          </p>
          <div className="pt-2 text-xs font-mono text-primary">
            Rule: Queued (Instant Wallet Credit) | Processing (Locked)
          </div>
        </div>

        {/* Card 3: Security & Payment Isolation */}
        <div className="p-6 rounded-2xl bg-surface-container border border-outline-variant/30 space-y-3">
          <div className="flex items-center gap-3 text-primary">
            <span className="material-symbols-outlined text-2xl">security</span>
            <h2 className="text-lg font-bold">Payment & Security Standards</h2>
          </div>
          <p className="text-xs text-on-surface-variant leading-relaxed">
            Razorpay HMAC SHA-256 webhook validation protects financial ledger. Raw card data is never processed or retained on PrintIt application servers (PCI-DSS compliant hosted capture).
          </p>
          <div className="pt-2 text-xs font-mono text-primary">
            Standard: HMAC SHA-256 & PCI-DSS Hosted Gateway
          </div>
        </div>

        {/* Card 4: Store Pickup & QR Verification */}
        <div className="p-6 rounded-2xl bg-surface-container border border-outline-variant/30 space-y-3">
          <div className="flex items-center gap-3 text-primary">
            <span className="material-symbols-outlined text-2xl">qr_code_scanner</span>
            <h2 className="text-lg font-bold">In-Store Fulfillment & QR Verification</h2>
          </div>
          <p className="text-xs text-on-surface-variant leading-relaxed">
            All customer purchases are completed via physical in-store collection at vendor locations. Order handover requires scanning or entering the customer's unique 4-digit verification code.
          </p>
          <div className="pt-2 text-xs font-mono text-primary">
            Fulfillment: Physical Store Pickup (Zero Courier Shipping)
          </div>
        </div>
      </div>
    </div>
  );
};

export default LegalDocuments;
