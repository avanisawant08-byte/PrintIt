import React from 'react';
import { Link } from 'react-router-dom';

const RefundCancellationPolicy = () => {
  return (
    <div className="min-h-screen bg-background text-on-background py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-10 shadow-xl">
        <div className="flex items-center justify-between border-b border-outline-variant/20 pb-6 mb-8">
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-primary font-label-md">
              Order Policies
            </span>
            <h1 className="text-3xl font-extrabold text-on-surface mt-1 font-display-lg">
              Refund & Cancellation Policy
            </h1>
            <p className="text-xs text-on-surface-variant mt-1 font-label-md">
              Effective Date: January 1, 2026 | Platform Version: 1.0.0
            </p>
          </div>
          <Link
            to="/"
            className="px-4 py-2 rounded-xl bg-surface-container-highest border border-outline-variant text-xs text-on-surface hover:bg-surface-variant transition-colors flex items-center gap-1.5"
          >
            <span className="material-symbols-outlined text-sm">arrow_back</span>
            <span>Back</span>
          </Link>
        </div>

        <div className="space-y-8 text-sm text-on-surface-variant leading-relaxed">
          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">1. Order State Machine & Cancellation Windows</h2>
            <p>
              Print orders are processed through a structured sequential queue:
            </p>
            <div className="my-4 p-4 rounded-xl bg-surface-container-highest/60 border border-outline-variant/30 font-label-md text-xs text-on-surface space-y-1">
              <div>QUEUED ➔ PRINTING / PROCESSING ➔ READY FOR PICKUP ➔ COMPLETED</div>
            </div>
            <ul className="list-disc list-inside space-y-2 ml-2">
              <li>
                <strong>Cancellations Allowed (Status: Queued):</strong> While your order remains in <code>queued</code> status waiting to be accepted by the shopkeeper, you may cancel it at any time with a single tap in the application.
              </li>
              <li>
                <strong>Cancellations Locked (Status: Printing / Ready):</strong> Once the shop owner has accepted your order and printing has commenced, cancellation is strictly locked. Custom printed physical paper cannot be repurposed or restocked.
              </li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">2. Automated Refund Mechanism</h2>
            <p>
              When a valid cancellation is confirmed in the <code>queued</code> state:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mt-2">
              <li>
                <strong>Instant Wallet Credit:</strong> The entire order amount (100% of payment) is atomically credited back to your PrintIt digital wallet (<code>wallet_balance</code>).
              </li>
              <li>
                <strong>Zero Cancellation Surcharge:</strong> PrintIt does not deduct any cancellation penalty or processing fee for queued cancellations.
              </li>
              <li>
                <strong>Immediate Re-usability:</strong> Refunded wallet funds are immediately available to apply toward any future order at any partner shop.
              </li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">3. Defective Prints & Misprint Policy</h2>
            <p>
              If a shop produces an illegible, smeared, cut-off, or corrupted print due to printer hardware error, notify the shopkeeper immediately at pickup or raise a ticket via the <strong>Support Center</strong> within 24 hours with an attached photograph. Verified vendor defects are subject to an immediate free reprint or full wallet refund.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">4. Stationery & Manuals Return Policy</h2>
            <p>
              Stationery products (manuals, study materials, notebooks) purchased through the marketplace may be cancelled prior to store collection. Once collected, returns are only accepted in cases of defective binding, missing pages, or incorrect item handover.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">5. Delivery & Shipping Notice</h2>
            <p>
              All orders placed on PrintIt are designated for in-person physical store pickup (Express Pickup or Scheduled Pickup). PrintIt does not operate third-party courier shipping.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
};

export default RefundCancellationPolicy;
