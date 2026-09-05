import React, { useState } from 'react';
import { Link } from 'react-router-dom';

const PartnerSupport = () => {
  const [openFaq, setOpenFaq] = useState(null);

  const faqs = [
    {
      q: 'How do I accept and process orders from the Live Queue?',
      a: 'When an incoming print job arrives in your Live Queue, review the document specifications (color, page count, binding). Click "Start Printing" to notify the customer that printing is underway, and then click "Mark Ready" once the prints are packed and ready for pickup.'
    },
    {
      q: 'How does pickup verification work with the customer QR code?',
      a: 'When the customer arrives at your shop, ask them to display their in-app Order Verification QR code. Scan the code using your mobile scanner or verify the 4-digit order token displayed on the order ticket to confirm handover.'
    },
    {
      q: 'How and when are shop earnings paid out?',
      a: 'Your net earnings accumulate in your partner balance after every completed order. You can request a payout anytime from your Wallet tab. Payout requests are verified by platform administrators and settled directly to your registered bank account.'
    },
    {
      q: 'What should I do if a paper jam or printer fault occurs during printing?',
      a: 'If a print job cannot be completed due to hardware failure, inform the customer immediately. You can flag the order or contact platform support to trigger an immediate automated refund to the customer wallet so they can re-order.'
    },
    {
      q: 'How do I update my print pricing rules?',
      a: 'Navigate to the "Pricing Rules" tab from your dashboard menu. You can configure unit costs for Black & White vs. Color printing, A4/A3 paper sizing, single/double sided, and staple or spiral binding add-ons.'
    }
  ];

  return (
    <div className="space-y-8 max-w-5xl">
      <div>
        <h1 className="text-2xl font-bold text-on-surface font-display-lg">Partner Support & FAQ</h1>
        <p className="text-sm text-on-surface-variant mt-1">
          Find answers to operational questions, contact support, and access platform compliance documentation.
        </p>
      </div>

      {/* Support Contact Card */}
      <div className="p-6 rounded-2xl bg-surface-container border border-outline-variant/30 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-primary/20 text-primary flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-2xl">support_agent</span>
          </div>
          <div>
            <h3 className="font-bold text-on-surface">Need Help with an Order or Payout?</h3>
            <p className="text-xs text-on-surface-variant mt-0.5">
              Our partner operations desk is active daily to assist with technical, order, or payout queries.
            </p>
          </div>
        </div>
        <a
          href="mailto:support@printit.com?subject=PrintIt%20Partner%20Support%20Inquiry"
          className="px-5 py-2.5 rounded-xl bg-primary text-on-primary font-medium text-sm hover:opacity-90 transition-opacity flex items-center gap-2 shrink-0 shadow-md"
        >
          <span className="material-symbols-outlined text-base">mail</span>
          <span>Contact Partner Desk</span>
        </a>
      </div>

      {/* FAQ Accordion */}
      <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm">
        <h2 className="text-lg font-bold text-on-surface mb-4">Frequently Asked Questions</h2>
        <div className="divide-y divide-outline-variant/20">
          {faqs.map((faq, index) => {
            const isOpen = openFaq === index;
            return (
              <div key={index} className="py-4 first:pt-0 last:pb-0">
                <button
                  onClick={() => setOpenFaq(isOpen ? null : index)}
                  className="w-full text-left flex items-center justify-between gap-4 font-medium text-sm text-on-surface hover:text-primary transition-colors"
                  aria-expanded={isOpen}
                >
                  <span>{faq.q}</span>
                  <span className="material-symbols-outlined text-lg text-on-surface-variant transition-transform duration-200" style={{ transform: isOpen ? 'rotate(180deg)' : 'rotate(0)' }}>
                    expand_more
                  </span>
                </button>
                {isOpen && (
                  <p className="mt-2.5 text-xs sm:text-sm text-on-surface-variant leading-relaxed pr-8">
                    {faq.a}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Legal & Policy Links */}
      <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm">
        <h2 className="text-lg font-bold text-on-surface mb-4">Platform Policies & Compliance</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 text-sm">
          <Link
            to="/privacy"
            className="p-3.5 rounded-xl bg-surface-container-highest/50 border border-outline-variant/20 hover:border-primary/50 text-on-surface flex items-center justify-between group transition-colors"
          >
            <span>Privacy Policy</span>
            <span className="material-symbols-outlined text-base text-on-surface-variant group-hover:text-primary transition-colors">arrow_forward</span>
          </Link>
          <Link
            to="/terms"
            className="p-3.5 rounded-xl bg-surface-container-highest/50 border border-outline-variant/20 hover:border-primary/50 text-on-surface flex items-center justify-between group transition-colors"
          >
            <span>Terms of Service</span>
            <span className="material-symbols-outlined text-base text-on-surface-variant group-hover:text-primary transition-colors">arrow_forward</span>
          </Link>
          <Link
            to="/refund-policy"
            className="p-3.5 rounded-xl bg-surface-container-highest/50 border border-outline-variant/20 hover:border-primary/50 text-on-surface flex items-center justify-between group transition-colors"
          >
            <span>Refund & Cancellation Policy</span>
            <span className="material-symbols-outlined text-base text-on-surface-variant group-hover:text-primary transition-colors">arrow_forward</span>
          </Link>
          <Link
            to="/security"
            className="p-3.5 rounded-xl bg-surface-container-highest/50 border border-outline-variant/20 hover:border-primary/50 text-on-surface flex items-center justify-between group transition-colors"
          >
            <span>Security & Disclosure</span>
            <span className="material-symbols-outlined text-base text-on-surface-variant group-hover:text-primary transition-colors">arrow_forward</span>
          </Link>
          <Link
            to="/accessibility"
            className="p-3.5 rounded-xl bg-surface-container-highest/50 border border-outline-variant/20 hover:border-primary/50 text-on-surface flex items-center justify-between group transition-colors"
          >
            <span>Accessibility Statement</span>
            <span className="material-symbols-outlined text-base text-on-surface-variant group-hover:text-primary transition-colors">arrow_forward</span>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default PartnerSupport;
